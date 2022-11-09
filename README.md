# ⚙️ Pre-installation

## Create bootable media with the OS image

To download Arch Linux, head to https://archlinux.org/download/ and download the latest release
(~800MB). Once downloaded you need to put the image on a USB, you can use different tools on 
MacOS and Windows, like Balena Etcher, WonderISO, Fedora Media Writer, etc. Choose one and 
proceed.

From your UEFI screen disable secure boot (we can re-enable it later). On some systems secure 
boot could disallow Arch Linux to boot properly. If you are creating a dual boot system (e.g.
Windows + Linux) it is important to disable fast startup and hibernation features on Windows.


## Boot from installation medium

Plug the USB, turn on the machine and access the BIOS firmware UI (it is done in different ways 
depending on the specific hardware configuration). From there pick the bootable USB drive as 
the device to boot from. The installation process will ask you confirmation for OS 
installation, proceed and wait the Arch Linux installer to boot. If everything works as 
expected you should see the terminal in a screen like the one showed below. The Arch installer
doesn't have any graphical user interface to automate the installation.

<img src="../../01_arch_linux_installation/assets/01-01-installer-boot.png" width="900"/>

Make sure that you've booted in UEFI mode and not in BIOS mode. The following command will 
output a bunch of UEFI related files if the boot started in UEFI mode properly. In case of a 
BIOS boot, the _efi_ directory won't even exist inside the `/sys/firmware` directory.

````shell
$ ls /sys/firmware/efi/efivars
````

By default, the console assumes that you have a standard US keyboard layout. You can change 
the layout to a different one. All the available keymaps are usually kept inside the 
`/usr/share/kbd/keymaps` directory in the form of map.gz files.
```shell
$ ls /usr/share/kbd/keymaps/**/*.map.gz
```

Choose the keyboard layout you prefer, load it and save the change with the `loadkeys` command.
```shell
# <layout> is the name of a layout found in/usr/share/kbd/keymaps/**/*.map.gz
# without the map.gz extension
$ loadkeys <layout> 
```

### Network connection
Before proceeding, we must connect to internet in our USB installation environment.

If you're using a wired network you could have a working internet connection already working. 
To test it out, ping any public addresses. If you have a wireless connection you have to 
configure it manually. The live environment comes with the iwd or iNet wireless daemon 
package. You can use this package to connect to a nearby wireless network.

```shell
# starts an interactive CLI
$ iwctl 
  # list wifi cards/devices in your machine (e.g. wlan0)
  > device list
  # scan wifi networks using that wifi card
  > station <device> scan
  > station <device> get-networks
  # connect to the network you choose, the 
  # CLI should ask you for credentials
  > station <device> connect <SSID>
  # if all good, exit from the CLI
  > exit
  
# check everything works correctly
$ ping 8.8.8.8
```

Finally sync the machine clock using the NTP time protocol:
```shell
$ timedatectl set-ntp true
```

## Disk partitioning
Disk partitioning is dangerous if you don't know what you are doing, if you mess up your 
partitions, you lose data on your disks. So keep attention!

Start with `lsblk` or `fdisk` to obtain information about the current disks and partitioning. 
We will go with the second option. List the partition tables for all the available devices on 
your computer. Ignore any device not related to physical disks and consider only those (should 
be named like e.g. _/dev/sda_, _/dev/nvme0n1_, etc. depending on your hardware). Remember: 
these files under _/dev_ represent devices/pieces of hardware connected to your machine and
exposed as block files (block for disks).

```shell
$ fdisk -l
```

Choose a disk to install the OS, take note of the corresponding block file under /dev and 
inspect the disk and its partitions. The command will output the partition table for the 
device. Partitions are usually named after the name of the disk, so if you have _/dev/nvme0n1_ 
as a disk name, partitions are named _/dev/nvme0n1p1_, _/dev/nvme0n1p2_, etc.

```shell
$ fdisk </path/to/your/device/file> -l
```

Once you collect all useful information, use `gdisk` to start re-partitioning the disk (`gdisk`
is the user-friendly version of `fdisk`, it uses an interactive CLI). You really want to have 
a GPT partitioned disk, MBR is considered legacy and must be avoided.

You need at least three partitions to install Arch Linux:

| Partition            | Usage                                                       | Space   | Type             | Filesystem to use | Temporary mount point                   |
|:---------------------|:------------------------------------------------------------|:--------|:-----------------|:------------------|:----------------------------------------|
| EFI system partition | used to store files required by the UEFI firmware           | 500MB   | EFI              | FAT32             | /mnt                                    |
| ROOT partition       | for installing the distribution itself and store user files | > 100GB | Linux filesystem | EXT4              | /mnt/boot                               |
| SWAP partition       | space dedicated for swapping (overflow space for your RAM)  | 10GB    | Linux swap       |                   | -                                       |

Note that if you are creating a dual boot setup some partitions could be already present. You 
don't want to touch partitions dedicated to other OS. Also note that in this case the EFI 
partitions is already present since it's shared between multiple installed OS. Don't touch
that, just create the other partitions and move on.

```shell
# start the gdisk CLI
$ gdisk </path/to/your/device/file>
  ### GDISK COMMANDS 
  # show help and commands
  > ?
  # list current partitions on disk
  > p 
  # create new partition, it will ask first and last sector so the
  # size of the partition will be (last sector - first sector)
  # OR you can input the first sector and the size directly as the 
  # last sector field e.g. +100G
  > n
  # show type of partitions, then choose appropriate value
  # (EFI type, Linux filesystem, etc)
  > l
  # confirm partitions creation and exit
  > w
  
  ### PARTITIONS CREATION
  # create EFI partition, size = +500M, type code = ef00 
  > n 
  # create ROOT partition, size = +100G, type code = 8300 
  > n 
  # create EFI partition, size = +10G, type code = 8200 
  > n
  # check everything is correct, then write and exit 
  > p
  > w
```

After writing the partitions check again everything worked as expected. Take note of the 
partition device names (e.g. _/dev/nvme0n1p1_, _/dev/nvme0n1p2_, etc.), you must refer to them 
in the next step.

```shell
$ fdisk /dev/sda -l
```

<img src="../../01_arch_linux_installation/assets/01-02-partitions.png" width="600"/>


## Filesystems and mount points

Partitioning by itself is not enough for the OS to use the partitions. We need to format the 
partitions. To do this we must create a filesystem on each partition. A file system is a 
standard that defined how files and data are stored and organized on disk. The most popular 
Linux filesystems are _ext3_ and _ext4_. The filesystem is a feature of a partition, recorded
along with the partitions themselves in the partition table, therefore they are used to
indicate how to interpret/manage partitions to the OS.

The EFI partition should be formatted with a FAT32 filesystem. It is a standard for EFI 
partitions and all OS rely on this to read the EFI partition.

```shell
# format the EFI partition with a FAT32 filesystem
# <path/to/the/partition/device> is not the disk itself (/dev/nvme0n1), but
# the device file referring to the EFI partition (e.g. /dev/nvme0n1p1)
$ mkfs.fat -F32 <path/to/the/EFI_partition/file>

# format the ROOT partition with a EXT4 filesystem
$ mkfs.ext4 <path/to/the/ROOT_partition/file>

# format the SWAP partition
$ mkswap <path/to/the/SWAP_partition/file>
```

⚠️ TO CHECK ⚠️ 
Note that now we are operating inside the Arch Linux Live Environment and the filesystem rooted 
at `/` contains the files loaded from the USB installation medium. This filesystem is not really 
backed by the USB storage, but is simulated on the RAM (this is how live installations works). 
Writing/modifying files in the current filesystem will not result in permanent modifications 
of the USB contents. So the files we can visualize (until the end of the current installation 
step) are files of an Arch Linux system, but in RAM and loaded from the USB Live image. ⚠️

We need now to mount our disk partitions on the filesystem, following the table below. The 
`/mnt` directory is generally used for temporary mounts so it's fine to use it now. Note that 
in the final installation ROOT and EFI partitions will be mounted on proper locations.

| Partition            | Filesystem     | Temporary mount point | 
|:---------------------|:---------------|:----------------------|
| ROOT partition       | EXT4           | /mnt                  |
| EFI system partition | FAT32          | /mnt/boot             |
| SWAP partition       | -              | -                     |


```shell
# mount the ROOT partition on the file system
$ mount --mkdir /dev/<ROOT_partition_file> /mnt

# mount the EFI partition on the file system
$ mount --mkdir /dev/<EFI_partition_file> /mnt/boot

# don't mount the SWAP partition, just tell Linux to use it
$ swapon /dev/<SWAP_partition_file>
```

## Configure mirror servers

At this point we have some partitions on one or more disks, properly formatted and temporarily 
mounted. We need now to configure the mirrors to download Arch Linux packages. The installer
comes with `reflector`, a script able to retrieve the latest mirror list from the Arch Linux
Mirror Status page.

Reflector can generate a list of mirrors based on a set of requirements. In this case, I want 
a list of mirrors that were synchronized within the last 12 hours and that are located in 
Italy (you should use your country), and sort the mirrors by download speed. The save command 
will persist the result in the specified file. You can run the reflector without saving the 
output just to see what the script produces (the list of mirrors).

The file at `/etc/pacman.d/mirrorlist` is a configuration file used by pacman to know which 
mirrors to use (in descending order of preference). Now when we'll install Arch Linux in the 
next steps, the OS and all packages will be downloaded from the mirrors indicated there.

```bash
$ reflector \
  --download-timeout 60 \
  --country Italy \
  --age 12 \
  --protocol https \
  --sort rate \
  --save /etc/pacman.d/mirrorlist
```



# ⚙️️ Installation

## Install OS

First of all let's update packages of the Live OS.

```shell
$ pacman -Sy
```

Once the update process is finished, you can use the `pacstrap` script to install the Arch 
Linux system. The `pacstrap` script can install packages to a specified new root directory 
(`/mnt`). As you may remember, the root partition was mounted on the `/mnt`mount point, so 
that's what you'll use with this script.

```shell
$ pacstrap /mnt \ 
    # the linux kernel and most
    # common linux firmwares
    linux \
    linux-firmware \  
    # minimal package set to define a 
    # basic Arch Linux installation
    base \
    # linux utilities and some useful 
    # linux tools and commands
    sudo \         
    networkmanager
    # C compiler & dev utilities
    gcc \
    git \
    make \
    vim 
```

Now the Linux kernel is installed along with some utilities (in the temporary mounted disk
partition), but it's not enough. We need to configure some more things to have a proper 
running system.

### Configure partitions mounts at boot

We manually mounted partitions into the file system, but these mounts are not yet permanent.
The `/mnt/etc/fstab` file can be used to define how disk partitions, various other block
devices, or remote file systems should be mounted into the file system at boot.

The `genstab` script simply detects all the current mounts below a given mount point and
prints them in fstab-compatible format to standard output. We can redirect the output to 
the `/mnt/etc/fstab` file, so the OS will re-mount all the partitions at boot.

```shell
$ genfstab -U /mnt >> /mnt/etc/fstab
```

Double-check the `/mnt/etc/fstab` file. If everything looks good, we can proceed.

### 📝 Change root to new root partition 

From here, it is convenient to change root inside the new root partitions (where the new OS
is installed) and run the commands inside the chroot (called also _root jail_).

A `chroot` on Unix and Unix-like operating systems is an operation that changes the apparent
root directory for the current running process and its children. A program that is run in such
a modified environment cannot name (and therefore normally cannot access) files outside the
designated directory tree. The term _chroot_ may refer to the _chroot system call_ or the
_chroot wrapper program_. The modified environment is called a _chroot jail_.

```shell
$ arch-chroot /mnt
```

## Install the boot loader (GRUB)

### Introduction

A short recap of the boot process under UEFI before installing the GRUB boot loader. Below
there's the output of the `efibootmgr` command. It shows the boot entries saved in the machine
NVRAM (where boot entries are stored in hardware).

```shell
$ efibootmgr -v
  BootCurrent: 0002
  Timeout: 3 seconds
  BootOrder: 0003,0002,0000,0004        # order in which the entries in the list will be tried.
  Boot0000* CD/DVD Drive  BIOS(3,0,00)
  Boot0001* Hard Drive    HD(2,0,00)
  Boot0002* Fedora        HD(1,800,61800,6d98f360-cb3e-4727-8fed-5ce0c040365d)File(\EFI\fedora\grubx64.efi)
  Boot0003* opensuse      HD(1,800,61800,6d98f360-cb3e-4727-8fed-5ce0c040365d)File(\EFI\opensuse\grubx64.efi)
  Boot0004* Hard Drive    BIOS(2,0,00)P0: ST1500DM003-9YN16G
```

Under the UEFI firmware, the boot process looks like this:
- the system is switched on, the power-on self-test (POST) is executed
- after POST, the UEFI firmware initializes the hardware required for booting (disk,
  keyboard, etc.)
- the firmware reads the boot entries in the NVRAM to determine which EFI application are
  present and which to launch and from where (from which disk and partition)
- boot entries can be of one of this type:

  - _simply a disk (BIOS compatibility)_: BIOS compatible booting mechanism, in the example
    below boot entries 0000 and 0004

  - _fallback UEFI boot entries_: for those, the firmware will look through each EFI system
    partition on the disk in the order they exist on the disk. Within the ESP, it will look
    for a file with a specific name and location. Example: on an x86-64 PC, it will look for
    the file `\EFI\BOOT\BOOTx64.EFI`. This mechanism is not designed for booting permanently
    installed OSes. It's more designed for booting hot-pluggable, device-agnostic media, like
    live images and OS install media. In the example below boot entry 0001

  - _full UEFI native boot entries_: typical entries for operating systems permanently
    installed to permanent storage devices. These entries show us the full power of the UEFI
    boot mechanism, by not just saying "boot from this disk", but "boot this specific
    bootloader in this specific location on this specific disk". In the example below boot
    entries 0002 and 0003

- the firmware launches the EFI application: this could be a boot loader or the Arch kernel
  itself using EFISTUB, it could be some other EFI application such as the UEFI shell or a
  boot manager like systemd-boot or rEFInd.


The UEFI native mechanism is the one to preferably adopt when installing a OS. Operating
systems should make themselves available for booting in this way: the OS is intended to
install a bootloader which loads the OS kernel, in an EFI system partition, and add an entry
to the UEFI boot manager configuration with a proper name and the location of the bootloader
(in EFI executable format) that is could be used to load that operating system.

More info about the UEFI boot process:
https://www.happyassassin.net/posts/2014/01/25/uefi-boot-how-does-that-actually-work-then/

### Update CPU microcode

📝️ Inside the _chroot_ at the mount point of the root partition (`/mnt/`).

Processors may have faulty behaviour, which the kernel can correct by updating the microcode
on startup. Processor manufacturers release stability and security updates to the processor
microcode. These updates provide bug fixes that can be critical to the stability of your system.

```shell
# for amd processors
$ pacman -S amd-ucode
# for intel processors
$ pacman -S intel-ucode
```

### Installation

📝️ Inside the _chroot_ at the mount point of the root partition (`/mnt/`).

Let's proceed with the installation. First, install the packages `grub` and `efibootmgr`:
GRUB is the bootloader itself while `efibootmgr` is used by the GRUB installation script
(or by us) to write boot entries to NVRAM.

```shell
$ pacman -S grub efibootmgr
```

We need to mount the EFI partition (if not already mounted previously) on `/mnt/boot` if we
are outside the _chroot_ or `/boot` if we are inside or we already logged in the newly
created OS (somehow). The following commands assume we are inside the _chroot_. If for some
reason it is necessary to run grub-install from outside of the installed system, append the
_--boot-directory=_ option with the path to the mounted _/boot_ directory, e.g
_--boot-directory=/mnt/boot_.

Remember to use the correct disk and partition here, since we need a specific filesystem type
(FAT32) to install the boot loader into.

After mounting the partition, execute the `grub-install` command to install the GRUB EFI
application _grubx64.efi_ to `${ESP}/EFI/GRUB/` and install its modules to
`${ESP}/grub/x86_64-efi/`.

```shell
# mount EFI partition if not already mounted
ESP="/boot"
$ mount --mkdir /dev/<efi_system_partition> ${ESP}

# install grub
$ grub-install \
    --target=x86_64-efi \
    --bootloader-id=arch-<your-name> \
    --efi-directory=${ESP}
```

The `grub-install` command also tries to create an entry in the firmware boot manager, named
`arch-<your-name>` in the above example. This can fail if your boot entries are full; use
`efibootmgr` to remove unnecessary entries.

Finally we generate configuration files for GRUB. Use the `grub-mkconfig` command to generate
the GRUB configuration file and saves it to a given target location. In this case
`/boot/grub/grub.cfg` is the target location.

```shell
$ grub-mkconfig -o /boot/grub/grub.cfg
```










## OS configuration

### Configure time zone

📝️ Inside the _chroot_ at the mount point of the root partition (`/mnt/`).

List the available timezones then choose the correct one creating a symbolic link.

```shell
$ ls -alh /usr/share/zoneinfo
$ ln -sf /usr/share/zoneinfo/<region>/<city> /etc/localtime
$ hwclock --systohc # generate /etc/adjtime
```

### Configure languages

📝️ Inside the _chroot_ at the mount point of the root partition (`/mnt/`).

First, you'll have to edit the `etc/locale.gen` file according to your localization. Open the 
file in a text editor and uncomment the locale you want to use. Then run the `locale-gen` 
command that will read your `/etc/locale.gen` file and generate the locales accordingly.

```shell
# uncomment languages chosen
$ vim /etc/locale.gen 
# generate and save locale files
$ locale-gen
```

Now that you've enabled multiple languages, you'll have to tell Arch Linux which one to use by 
default. To do so, open the `/etc/locale.conf` file and add the following line to it, modified
accordingly based on the language chosen.

```shell
$ touch /etc/locale.conf
$ echo "LANG=en_US.UTF-8" > /etc/locale.conf 
$ cat /etc/locale.conf
LANG=en_US.UTF-8
```

You can always go back to the `/etc/locale.gen` file and add or remove languages from it and 
run again `locale-gen`.

If you've made any changes to your console keymaps in the first step of installation, you may 
want to persist them now. To do so, open the `/etc/vconsole.conf` file and add your preferred 
keymaps there.

```shell
$ touch /etc/vconsole.conf
$ echo "KEYMAP=it" > /etc/vconsole.conf 
$ cat /etc/vconsole.conf
KEYMAP=it
```

### Configure basic networking

📝️ Inside the _chroot_ at the mount point of the root partition (`/mnt/`).

I use the `networkmanager` package to handle connection, because it is easier to use 
and implements different functionalities in one place. Alternatively there are different
options. Personally I tried with `wpa_supplicant` + `dhcp_client` to connect to a wi-fi
access point and handle IP assignation via DHCP.

```shell
# install the package if not done previously
$ pacman -S networkmanager
# enable it as a systemd unit, and disable other 
# network related tools that could interfere
$ systemctl stop wpa_supplicant
$ systemctl disable wpa_supplicant
$ systemctl enable NetworkManager
```

We need also to configure the host name for this machine, modifying the `/etc/hostname` file.
I usually use my machine model + my name as my hostname. Additionally it's a good thing to 
modify the `/etc/hosts` file to provide some DNS records. 

```shell
$ cat /etc/hostname
andrea-<machine>

$ cat /etc/hosts
127.0.0.1        localhost
::1              localhost
127.0.1.1        andrea-<machine>
```

### Change root user password

📝️ Inside the _chroot_ at the mount point of the root partition (`/mnt/`).

The passwd command lets you change the password for a user. By default it affects the current 
user's password which is the root right now. Do it and follow the prompt.

```shell
$ passwd
```

### Add non-root user

📝️ Inside the _chroot_ at the mount point of the root partition (`/mnt/`).

The installation leaves by default only one user: the root superuser. Using your Linux system 
as the root user for long is not a good idea. So creating a non-root user is important. The 
`wheel` group is the administration group, commonly used to give privileges to perform 
administrative actions. Create a new user and change its password.

```shell
# -m = add corresponding home directory
# -G = add to indicated group 
$ useradd -m -G wheel <username>

# change password for newly created user
$ passwd <username>
```

If not already present add administration privileges for the new user. Open `/etc/sudoers` and 
uncomment the following line. Note that we should use `visudo` to edit this file, but.. keep
attention and do it manually.

```shell
$ vim /etc/sudoers
# uncomment this
%wheel ALL=(ALL) ALL
```

Some more info on how `sudo` and its configuration file works: 
https://www.digitalocean.com/community/tutorials/how-to-edit-the-sudoers-file

### End
Congratulations, you now have a working Arch Linux installation. At this point, you can exit
the Arch-Chroot environment, unmount the partition, and reboot. 

```bash
$ exit              # from chroot
$ umount -R /mnt    # unmount partitions
$ reboot
```
If you are fine with a _shell-only_ OS you are good. Otherwise proceed with the next chapters.
# ⚙️ Post installation

## Install graphical environment
To run programs with graphical user interfaces on your system, you'll have to install an 
X Window System implementation. The most common one is Xorg. To install Xorg, execute the
following command.

```shell
$ pacman -S xorg-server
```

Then you need to install graphic drivers, depending on your graphic card.

```shell
# for nvidia graphics processing unit
$ pacman -S nvidia nvidia-utils
# for amd discreet and integrated graphics processing unit
$ pacman -S xf86-video-amdgpu
# for intel integrated graphics processing unit
$ pacman -S xf86-video-intel
```

Finally install the desktop environment.

```shell
$ pacman -S plasma
```

Like gdm in GNOME, Plasma comes with `sddm` as the default display manager. A display manager, 
or login manager, is typically a graphical user interface that is displayed at the end of the
boot process in place of the default shell. 

Execute the following command to enable the service.

```shell
$ systemctl enable sddm
```

Alternatively, Plasma can start at boot immediately after the X server. See:
https://wiki.archlinux.org/title/KDE#From_the_console
# 🌐 Network

## Wireless connection

You should install and enable `networkmanager` if not already done previously. The package 
contains a daemon, a command line interface (`nmcli`) and a curses‐based interface (`nmtui`).

⚠️ The Live env has everything needed to connect to internet. If now you booted directly from 
the newly installed OS and you didn't install the network manager previously... well, you 
have to use an ethernet connection or re-boot from the Live env to install it.

```shell
# install network manager
$ pacman -Sy networkmanager
# start network manager
$ systemctl start NetworkManager
# enable network manager to start at boot
$ systemctl enable NetworkManager
```


Before proceeding, check if the driver for your network card has been loaded, check the 
output of the `lspci -k` or `lsusb -v`, something similar should appear in the drivers list:
```shell
$ lspci -k
# 06:00.0 Network controller: Intel Corporation WiFi Link 5100
#  	Subsystem: Intel Corporation WiFi Link 5100 AGN
#  	Kernel driver in use: iwlwifi
# 	Kernel modules: iwlwifi
```

Check if a corresponding network interface was created, usually the naming of the wireless 
network interfaces starts with the letter "w", e.g. wlan0 or wlp2s0:
```shell
$ ip link show
# <your-interface>: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state DOWN mode DORMANT qlen 1000
#    link/ether 00:60:64:37:4a:30 brd ff:ff:ff:ff:ff:ff
```

Then the network interface should be brought up with the command shown below. Check again 
the interface status to spot the UP keyword at the beginning of the row with `ip link`:
```shell
$ ip link set <your-interface> up
$ ip link show
#                                        here
#                                        | 
# <your-interface>: <BROADCAST,MULTICAST,UP,LOWER_UP> ....
```

```shell
# see a list of network devices and their state
$ nmcli device
# list nearby Wi-Fi networks
$ nmcli device wifi list

# connect to a Wi-Fi network
$ nmcli device wifi connect <SSID_or_BSSID> password <password>
# connect to a Wi-Fi on the wlan1 interface
$ nmcli device wifi connect <SSID_or_BSSID> password <password> ifname <wlan1> <profile_name>

# get a list of connections with their names, UUIDs, types and backing devices
$ nmcli connection show
# activate a connection (i.e. connect to a network with an existing profile)
$ nmcli connection up name_or_uuid
# delete a connection
$ nmcli connection delete name_or_uuid
```

The network interface should be UP in both places in the output of the `ip link` command:
```shell
$ ip link show
#                                        here                                 here
#                                        |                                    |
# <your-interface>: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DORMANT qlen 1000
#   link/ether 00:60:64:37:4a:30 brd ff:ff:ff:ff:ff:ff
```

NetworkManager has a global configuration file at `/etc/NetworkManager/NetworkManager.conf`. 
Additional configuration files can be placed in `/etc/NetworkManager/conf.d/`. Usually no 
configuration needs to be done to the global defaults. After editing a configuration file, 
the changes can be applied by running:

```shell
$ nmcli general reload
```

Note that by default NetworkManager uses its internal DHCP client. If you want to change it 
check: https://wiki.archlinux.org/title/NetworkManager#DHCP_client

# 📚 Programming languages and IDEs

## 🦫 Go & Goland

### Install Go

Before installing Go update all system packages.
```shell
$ sudo pacman -Syu
```

Proceed cleaning the old Go installation, downloading the desired version fo Go,
extracting and installing it.

```shell
# choose the desired version
GO_VER=1.19.3

# remove old Go installation
$ rm -rf /usr/local/go

# download the Go language archive and install it 
$ curl -L --output ./go${GO_VER}.linux-amd64.tar.gz https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz
$ tar -C /usr/local -xzf ./go${GO_VER}.linux-amd64.tar.gz
```

Add `/usr/local/go/bin` to the PATH environment variable. You can do this by adding the 
following line to your `$HOME/.profile` or `/etc/profile` (for a system-wide installation).

```shell
# add the line using redirection or do it manually using vim
$ echo "export PATH=${PATH}:/usr/local/go/bin" >> $HOME/.profile
$ source $HOME/.profile
```

Confirm everything is working.

```shell
$ go version
```

### Install Goland

To install Goland download it from the jetbrains.com site, decompress and extract the archive,
copy the contents into a proper directory.

```bash
GOLAND_VER="2022.2.4"
$ curl -L --output ./goland-${GOLAND_VER}.tar.gz https://download.jetbrains.com/go/goland-${GOLAND_VER}.tar.gz
$ tar xzf ./goland-${GOLAND_VER}.tar.gz -C /opt/
```

To run the IDE run the `goland.sh` script. You can eventually add this path to the PATH env 
var. During the first launch Goland will ask you to authenticate or provide the license.

```bash
$ /opt/goland-${GOLAND_VER}/bin/goland.sh
```

## 🦀 Rust & CLion

### Install Rust

The primary way that folks install Rust is through a tool called Rustup, which is a Rust 
installer and version management tool. When you install Rustup you’ll also get the latest
stable version of the Rust build tool and package manager, also known as Cargo.

```shell
# install rustup, rust and cargo
$ curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# can be run in the future to get rustup updates
$ rustup update

# check it worked
$ cargo --version
```

In the Rust development environment, all tools are installed to the `~/.cargo/bin` directory, 
and this is where you will find the Rust toolchain, including rustc, cargo, and rustup.

During installation rustup will attempt to configure the PATH adding this folder. Because of 
differences between platforms, command shells, and bugs in rustup, the modifications to 
PATH may not take effect until the console is restarted, or the user is logged out, or it 
may not succeed at all. 

If the automatic configuration failed, add `~/.cargo/bin` to PATH manually. Add the 
following line to your `$HOME/.profile` or `/etc/profile` (for a system-wide installation).

```shell
# add the line using redirection or do it manually using vim
$ echo "export PATH=${PATH}:~/.cargo/bin" >> $HOME/.profile
$ source $HOME/.profile

# check again
$ cargo --version
```

### Install CLion

To install CLion download it from the jetbrains.com site, decompress and extract the archive,
copy the contents into a proper directory.

```bash
CLION_VER="2022.2.4"
$ curl -L --output ./clion-${CLION_VER}.tar.gz https://download.jetbrains.com/cpp/CLion-${CLION_VER}.tar.gz
$ tar xzf ./clion-${CLION_VER}.tar.gz -C /opt/
```

To run the IDE run the `clion.sh` script. You can eventually add this path to the PATH env var.
During the first launch CLion will ask you to authenticate or provide the license.

```bash
$ /opt/clion-${CLION_VER}/bin/clion.sh
```

Inside the CLion IDE you must install the Rust plugin to allow the IDE to fully support Rust.


## 🐳 Docker

Install the `docker` and `docker-compose` packages. Next start and enable the `docker.service` 
and verify it works.

```shell
$ pacman -Sy docker
$ pacman -Sy docker-compose

$ systemctl start docker
$ systemctl enable docker

$ sudo docker info
```

Next, verify that you can run containers. The following command downloads the latest Arch 
Linux image and uses it to run a _hello world_ program within a container:

```shell
$ sudo docker run -it --rm alpine sh -c "echo hello world"
```

If you want to be able to run the docker CLI command as a non-root user, add your user to 
the `docker` user group, re-login, and restart `docker.service`.

```shell
$ sudo usermod -a -G docker <user>
$ cat /etc/group # verify it worked
```
# Concetti di base

Il core del sistema operativo è il `kernel`. Il kernel si occupa di gestire la memoria (RAM), 
gestire i processi del sistema (CPU), gestire i device fisici (comunicazione fra processi e 
hardware) e offrire agli applicativi accesso controllato all'hardware (tramite system call). 
Il kernel è monolitico ma modulare, cioè può estendere le sue capacità tramite module kernel 
caricabili a runtime.

Il sistema operativo si divide fra `kernel space` (processi e risorse usati dal kernel) e 
`user space` (processi applicativi). I programmi in user space interagiscono con l’hardware
comunicando col kernel via `system calls`. Una system call è una richiesta specifica 
al kernel, dove il kernel prende il controllo, esegue le operazioni richieste e restituisce 
il risultato e/o eventuali errori.

## Hardware

Quando un device è collegato un device driver detecta il device è genera un evento (uevent) 
che viene inoltrato ad un processo userspace chiamato `udev`. Quest’ultimo processa l’evento
creando una `device file` che rappresenta il device nella cartella, tipicamente in /dev (e.g. 
/dev/sdd1).

Il comando `dmesg` ottiene messagi e logs generati dal kernel. Questi messaggi contengono 
anche log relativi all’hardware, per cui è possibile debuggare o saperne di più sui device 
collegati tramite questo comando. Inoltre il comando `udevadm` interroga udev per ottenere 
informazioni sui device e sugli eventi udev. Il comando invece `lspci` riporta informazioni 
sugli hardware attaccati alle porte PCI. Il comando `lsblk` lista informazioni 
esclusivamente sui block devices, sui dischi e le loro partizioni. Il comando `lscpu` 
fornisce informazioni sulla CPU. Il comando `lsmem` fornisce informazioni sulla RAM 
(provare con e senza --summary è utile), mentre `free -m` fornisce informazioni sulla memoria 
usata e libera. Il comando `lshw` fornisce info su tutto l’hardware del sistema.

## Boot Sequence

Approfondimento **consigliato** su Linux boot sequence:
https://www.happyassassin.net/posts/2014/01/25/uefi-boot-how-does-that-actually-work-then/

Il boot di un sistema Linux è composto fondamentalmente da 4 step. 

**POST**. Componente base del firmware del sistema che si assicura che tutto l’hardware 
collegato funzioni correttamente.  

**UEFI** (rimpiazza BIOS). Firmware della scheda madre che si occupa di caricare in memoria ed 
avviare sulla CPU il primo non-firmware (tipicamente bootloader). UEFI è un firmware 
"intelligente" in grado di leggere certe partizioni da disco, in particolare quelle formattate
con filesystem EFI, dove tipicamente si trova il bootloader. Una piccola memoria persistente
(NVRAM) salva le `boot entries`, ovvero una lista di indicazioni su come e da dove eseguire il
successivo step di boot. La NVRAM viene letta all'avvio dal firmware UEFI (consiglio link 
sopra per una spiegazione più completa).

**Bootloader (GRUB)**. Si occupa di caricare il kernel in memoria e gli da il controllo 
della CPU. 

**Kernel init**. Il sistema operativo inizializza driver, memoria, strutture dati interne 
etc. 

**User space init**. Avvia il processo init (PID 1) dello user space, lo standard è `systemd` 
ai giorni nostri.

Il runlevel è una modalità operativa del sistema operativo, ad esempio il boot fino al 
terminale (raw) è considerato livello 3, per interfaccia grafica tipicamente 5. Per ogni 
runlevel esistono delle componenti software da avviare e verificare ed ogni runlevel 
corrisponde ad un target systemd (e.s. 3 = terminale = multiuser.target, 5 = grafico = 
graphical.target).  Il comando systemctl può essere usato per verificare il runlevel di 
default e modificarlo. Notare che il termine runlevels è usato nei sistemi con sysV init. 
Questi sono stati sostituiti da target systemd nei sistemi basati su di esso. L'elenco 
completo dei runlevel e dei corrispondenti target di sistema è il seguente.

- runlevel 0 --> poweroff.target
- runlevel 1 --> rescue.target
- runlevel 2 --> multi-user.target
- runlevel 3 --> multi-user.target
- runlevel 4 --> multi-user.target
- runlevel 5 --> graphical.target
- runlevel 6 --> reboot.target

# 📄 Files

_Tutto è un file in Linux_ o quasi. Questo è un motto del mondo Linux, dove molte cose sono 
modellate ed esposte con un interfaccia file-simile.

Esistono diversi tipi di file:
- `regular files`, `-`: normal files
- `directory files`, `d`: directories
- special files:
  - `character files`, `c`: rappresentano device con cui si comunica in modo seriale
  - `block files`, `b`: rappresentano device con cui si comunica tramite blocchi di dati
  - `hard link files`, `-`: puntatori reali ad un file su disco, eliminare l’ultimo 
    significa eliminare il file
  - `soft link files`, `l`: shortcut verso un altro file, ma non i dati
  - `socket files`, `s`: file per comunicazione fra processi, via network e non
  - `pipes files`, `p`: file per comunicazione unidirezionale fra due processi

Esistono due comandi utili per esaminare il tipo di un file:

```shell
# reports the type and some additional info about a file
$ file <path>

# list file(s) and some infos like number of hard links, 
# permissions, size , etc.
$ ls -alh [file, ...] 
```

### Linux filesystem hierarchy

Tipicamente il filesystem linux è organizzato come segue, si tratta di convenzioni.

- `/home`   -> contiene le cartelle degli utenti è aliasata dal simbolo ~ (tilde)
- `/root`   -> home dell’utente root

- `/media`  -> montati filesystem di device esterni e rimuovili (es. USB)
- `/dev`    -> contiene i file speciali di tipo carattere e blocco (es. hard disk, mouse, etc)
- `/mnt`    -> filesystem montati temporaneamente

- `/opt`    -> dove vengono installati programmi di terze parti
- `/etc`    -> usata tipicamente per file di configurazione
- `/bin`    -> contiene i binari dei software di sistema
- `/lib`    -> contiene librerie (statiche e dinamiche) dei software di sistema
- `/usr`    -> contiene i binari di applicazioni degli utenti
- `/var`    -> contiene tipicamente dati scritti da applicazioni, es logs e caches

- `/tmp`    -> cartella con file e dati temporanei

## File manipulation

### Archival and compression

Il comando tar è usato per raggruppare file e creare archivi (definiti tarballs). Il comando
ls supporta un flag per vedere dentro una tarball. I comandi più utili sono:

```shell
# create tarball from specified files
$ tar -cf <output> <files..>

# create tarball and compress it
$ tar -zcf <output> <files..>

# look at the tarball contents
$ tar -tf <tarball>

# extract contents in specified directory
$ tar -xf <tarball> -C <output_dir>
```

La compressione riduce la dimensione dei file, fra le utilities più utili ci sono `bzip2`,
`gzip` e `xz`. Ogni utility può utilizzare diversi algoritmi e diversi livelli compressione.
Non serve sempre decomprimere un file per poterlo leggere, es. `zcat` legge un file
compresso senza decomprimerlo davvero.

```shell
# compress a file
$ gzip --keep -v <file>
# decompress a file
$ gzip/gunzip --keep -vd <file>
```

### Searching & grepping

Il comando `find` cerca un file in una specifica director. Il comando find è potente e 
supporta un ricco set di flags ed opzioni, è ricorsivo di default. Ecco alcuni esempi.

```shell
# general usage pattern
$ find <root-di-ricerca> -name <nome-file>

# find files under /home directory with a specific name
$ find /home -name file.txt
# same but ignore case, and use wildcards
$ find /home -iname "file.*"
# find directories, not files
$ find /home -type d -name <dir_name>

# find files whose permissions are 777 owned by the user
$ find /home -type f -perm 0777 -user <user>
# find files and for each of them exec a command
$ find /home -type f -perm 0777 -exec chmod 644 {} \;
```

Esiste anche il comando `locate` cerca un file nel filesystem, ma si base su un DB locale 
creato ed aggiornato periodicamente e non sempre necessariamente aggiornato (`updatedb` per 
riaggiornare). 

Il comando **`grep`** è molto utilizzato per cercare pattern all’interno di files.

- `-i` 	ricerca case insensitive (di default è case sensitive)
- `-r` 	ricerca ricorsiva in tutti i file a partire da una root
- `-v` 	ricerca per linee dove non c’è match col pattern
- `-w`	matcha solo le parole e non le substring di parole
- `-A <n>`	riporta i match e _n_ linee dopo
- `-B <n>`	riporta i match e _n_ linee prima

```shell
# general usage pattern
$ grep <options> <pattern> <files>

# grep lines starting with hello in txt files 
$ grep "^hello" *.txt
# grep lines starting with "fn" and some lines around, 
# recursive mode starting from current directory
$ grep -A 3 -B 2 -r -i "^fn" .
```

## Permissions

### Title3

```shell
```

```shell
```

```shell
```

### Title3

```shell
```

```shell
```

```shell
```

# ⚙️ Disks, partitions and filesystems

## Partitions

Le partizioni sono entità logiche (ma scritte anche su disco) che dividono un disco fisico 
e rendono indipendenti diverse porzioni dello stesso. Tipicamente partizioni diverse 
vengono  usate per diversi scopi e sulle partizioni possono essere configurati filesystems 
diversi (EXT4, EFI, FAT, SWAP, etc.).

Le partizioni sono invididuabili come block devices sotto `/dev`. Un block device è un file 
che rappresenta un pezzo di hardware che può immagazzinare dati, scritto a blocchi. Il comando 
`lsblk` lista i block devices, come da esempio sotto. Come si può notare esiste un disco 
_sda_ fisico, suddiviso in sezioni logiche che sono le partizioni. 

<img src="../../02_linux_handbook/assets/lsblk.png" width="600"/>

Ogni block device ha una versione `major` e `minor`. La major version (8) identifica il tipo 
di hardware mentre la minor version (0,1,2,3) individua le singole partizioni.

I comandi com3 `lsblk` o `fdisk` leggono le partizioni da una zona del disco chiamata
partition table (di due tipi, MBR o GPT),  che contiene tutte le informazioni su come e diviso
ed organizzato il disco, quante partizioni ha, che filesystem ha, etc. Esistono diversi 
schemi di organizzazione delle partizioni e quindi diversi tipi di partiton tables:
- `MBR`, master boot record: legacy, max 2TB, max 4 partizioni senza extended partitions
- `GPT`, guid partition table: nuova e migliore, unlimited number of partitions, no max size

Esistono 3 tipi di partizioni:
- primary partition: partizione usata per bootare l’OS, nel passato con MBR non potevano 
  esserci più di 4
- extended partition: partizione non usabile di per sè, solo un contenitore per partizioni 
  logiche, ha una sua partition table interna, legacy
- logical partition: sub-partizione contenuta nelle extended partition, legacy


Esistono diversi comandi per gestire le partizioni, fra cui `gdisk`. E' una CLI interattiva.

```shell
# start the gdisk CLI
$ gdisk </path/to/your/device/file>
  # show help and commands
  > ?
  # list current partitions on disk
  > p 
  # create new partition, it will ask first and last sector so the
  # size of the partition will be (last sector - first sector)
  # OR you can input the first sector and the size directly as the 
  # last sector field e.g. +100G
  > n
  # show type of partitions, then choose appropriate value
  # (EFI type, Linux filesystem, etc)
  > l
  # confirm partitions creation and exit
  > w
```

## Filesystems

Il partizionamento di per se non basta per rendere un disco utilizzabile dall’OS. Dobbiamo 
anche creare un filesystem nella partizione e poi montare la partizione su una directory. Un 
file system è uno standard che definisce come i file ed i dati devono essere organizzati 
su disco. 

I linux filesystem più diffusi sono `ext2`, `ext3` e `ext4`. I filesystem sono una
caratteristica di una partizione, scritti in corrispondenza delle partition entries della
partition table, servono quindi ad indicare agli OS come interpretare/trattare le partizioni 
di un disco.

Il comando `mkfs` crea un filesystem su una partizione. 
```shell
# create filesystem on specified partition
$ mkfs.ext4 <path/to/device>
```

Il comando `mount` monta una partizione in una locazione del filesystem.
```shell
# create partition on specified filesystem point
$ mount <path/to/device> <path/to/mount>
# list all mounts
$ mount
```
Per far permanere le modifiche (i mounts) è necessario editare il file `/etc/fstab`. Tale 
file raccoglie la lista dei mount point per ogni partizione ed il tipo di file system 
utilizzato, più alcune opzioni aggiuntive. La sintasi delle righe è la seguente: 

`<partizione> <mount-point> <fs-type> <options> <dump> <pass>` 
(dump controlla backups, pass controlla se bisogna fare check sul fs dopo crash)

<img src="../../02_linux_handbook/assets/fstab.png" width="600"/>

```shell
```

```shell
```

```shell
```

### Title3

```shell
```

```shell
```

```shell
```

### Title3

```shell
```

```shell
```

```shell
```

## Title2

```shell
```

```shell
```

```shell
```

### Title3

```shell
```

```shell
```

```shell
```

### Title3

```shell
```

```shell
```

```shell
```

