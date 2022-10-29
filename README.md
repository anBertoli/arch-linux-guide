# Pre-installation

## Create bootable media with the OS image

To download Arch Linux, head to https://archlinux.org/download/ and download the latest release (~800MB).
Once downloaded you need to put the image on a USB, you can use different tools on MacOS and Windows, like
Balena Etcher, WonderISO, Fedora Media Writer, etc. Choose one and proceed.

From your UEFI screen disable secure boot (we can re-enable it later). On some systems secure boot could
disallow Arch Linux to boot properly. If you are creating a dual boot system (e.g. Windows + Linux) it is
important to disable fast startup and hibernation features on Windows.


## Boot from installation medium

Plug the USB, turn on the machine and access the BIOS firmware UI (it is done in different ways depending
on the specific hardware configuration). From there pick the bootable USB drive as the device to boot from.
The installation process will ask you confirmation for OS installation, proceed and wait the Arch Linux
installer to boot. If everything works as expected you should see the terminal in a screen like the one
showed below. The Arch installer doesn't have any graphical user interface to automate the installation.

<img src="../images/01-01-installer-boot.png" alt="drawing" width="900"/>

Make sure that you've booted in UEFI mode and not in BIOS mode. The following command will output a bunch 
of UEFI related files if the boot started in UEFI mode properly. In case of a BIOS boot, the _efi_ directory
won't even exist inside the /sys/firmware directory.
````shell
$ ls /sys/firmware/efi/efivars
````

By default, the console assumes that you have a standard US keyboard layout. You can change the layout
to a different one. All the available keymaps are usually kept inside the /usr/share/kbd/keymaps directory
in the form of map.gz files.
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
To test it out, ping any public addresses. If you have a wireless connection you have to configure 
it manually. The live environment comes with the iwd or iNet wireless daemon package. You can use 
this package to connect to a nearby wireless network.

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

Finally sync the machine clock:
```shell
$ timedatectl set-ntp true
```

## Disk partitioning
Disk partitioning is dangerous if you don't know what you are doing, if you mess up your partitions, you lose 
data on your disks. So keep attention!

Start with `lsblk` or `fdisk` to obtain information about the current disks and partitioning. We will go with 
the second option. List the partition tables for all the available devices on your computer. Ignore any device 
not related to physical disks and consider only those (should be named like e.g. _/dev/sda_, _/dev/nvme0n1_, 
etc. depending on your hardware). Remember: these files under _/dev_ represent devices/pieces of hardware connected
to your machine and exposed as block files (block for disks).

```shell
$ fdisk -l
```

Choose a disk to install the OS, take note of the corresponding block file under /dev and inspect the disk 
and its partitions. The command will output the partition table for the device. Partitions are usually named 
after the name of the disk, so if you have _/dev/nvme0n1_ as a disk name, partitions are named _/dev/nvme0n1p1_,
_/dev/nvme0n1p2_, etc.

```shell
$ fdisk </path/to/your/device/file> -l
```

Once you collect all useful information, use `gdisk` to start re-partitioning the disk (_gdisk_ is the 
user-friendly version of _fdisk_, it uses an interactive CLI). You really want to have a GPT partitioned
disk, MBR is considered legacy and must be avoided.

You need at least three partitions to install Arch Linux:

| Partition            | Usage                                                       | Space   | Type             | Filesystem to use |
|:---------------------|:------------------------------------------------------------|:--------|:-----------------|:------------------|
| EFI system partition | used to store files required by the UEFI firmware           | 500MB   | EFI              | FAT32             | 
| ROOT partition       | for installing the distribution itself and store user files | > 100GB | Linux filesystem | EXT4              |
| SWAP partition       | space dedicated for swapping (overflow space for your RAM)  | 10GB    | Linux swap       |                   |

Note that if you are creating a dual boot setup some partitions could be already present. You don't want 
to touch partitions dedicated to other OS. Also note that in this case the EFI partitions is already present
since it's shared between multiple installed OS. Don't touch that, just create the other partitions and move on.

```shell
# start the gdisk CLI
gdisk </path/to/your/device/file>
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
  # create EFI partition, size = +500M, EFI type code = ef00 
  > n 
  # create ROOT partition, size = +100G, EFI type code = 8300 
  > n 
  # create EFI partition, size = +10G, EFI type code = 8200 
  > n
  # check everything is correct, then write and exit 
  > p
  > w
```

After writing the partitions check again everything worked as expected. Take note of the partition 
device names (e.g. _/dev/nvme0n1p1_, _/dev/nvme0n1p2_, etc.), you must refer to them in the next step.

```shell
$ fdisk /dev/sda -l
```
<img src="../images/01-02-partitions.png" alt="drawing" width="600"/>


## Filesystems and mounting (partitions formatting)

Partitioning by itself is not enough for the OS to use the partitions. We need to format the partitions.
To do this we must create a filesystem on each partition. A file system is a standard that defined how
files and data are stored and organized on disk. The most popular linux filesystems are ext3 and ext4. 
The filesystems are characteristic of a partition, recorded along with the partitions in the partition 
table, therefore they are used to indicate how to interpret/manage partitions to the OS.

The EFI partition should be formatted with a FAT32 filesystem. It is a standard for EFI partitons and 
all OSs rely on this to read the EFI partition.

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
at / contains the files loaded from the USB installation medium. This filesystem is not really 
backed by the USB storage, but is simulated on the RAM (this is how live installations works). 
Writing/modifying files in the current filesystem will not result in permanent modifications 
of the USB contents. So the files we can visualize (until the end of the current installation 
step) are like files of an Arch Linux, but in RAM and loaded from the USB Live image.

⚠️ TO CHECK ⚠️

We need now to mount our disk partitions on the filesystem, following the table below. The _/mnt_ 
directory is generally used for temporary mounts so it's fine to use it now. Note that in the final 
installation ROOT and EFI partitions will be mounted on proper locations.

| Partition            | Filesystem     | Mount point | 
|:---------------------|:---------------|:------------|
| ROOT partition       | EXT4           | /mnt        |
| EFI system partition | FAT32          | /mnt/boot   |
| SWAP partition       | -              | -           |


```shell
# mount the ROOT partition on the file system
$ mount --mkdir /dev/<ROOT_partition_file> /mnt

# mount the EFI partition on the file system
$ mount --mkdir /dev/<EFI_partition_file> /mnt/boot

# don't mount the SWAP partition, just tell Linux to use it
$ swapon /dev/sda3
```
## Network

### Wireless connection

At this point the system should have the wpa_supplicant package (`wpa_supplicant`, `wpa_cli`, `wpa_passphrase`, to 
connect and authenticate to a wireless access point, provided by the base arch installation), `dhcpcd` (dhcp client,
installed previously).

Check if the driver for your card has been loaded, check the output of the `lspci -k` or `lsusb -v`, something 
similar should appear in the drivers list:
```shell
$ lspci -k
# 06:00.0 Network controller: Intel Corporation WiFi Link 5100
#  	Subsystem: Intel Corporation WiFi Link 5100 AGN
#  	Kernel driver in use: iwlwifi
# 	Kernel modules: iwlwifi
```

Check if a corresponding network interface was created, usually the naming of the wireless network interfaces starts 
with the letter "w", e.g. wlan0 or wlp2s0:
```shell
$ ip link show
# <your-interface>: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state DOWN mode DORMANT qlen 1000
#    link/ether 00:60:64:37:4a:30 brd ff:ff:ff:ff:ff:ff
```

Then the network interface should be brought up with:
```shell
$ ip link set <your-interface> up
```

Check again the interface status to spot the UP keyword at the beginning of the row with `ip link`:
```shell
$ ip link show
#                                        here
#                                        | 
# <your-interface>: <BROADCAST,MULTICAST,UP,LOWER_UP> ....
```

Create the `/etc/wpa_supplicant/wpa_supplicant-<your-interface>.conf` file with the following content. This will allow
_wpa_cli_ to update the config file when needed:
```bash
$ touch /etc/wpa_supplicant/wpa_supplicant-<your-interface>.conf
```
```markdown
ctrl_interface=/run/wpa_supplicant
update_config=1
```

Now start `wpa_supplicant` on the right network interface with:
```shell
$ wpa_supplicant -B -i <your-interface> -c /etc/wpa_supplicant/wpa_supplicant-<your-interface>.conf
```

Now `wpa_cli` can be started and used to configure the connection:
```shell
$ wpa_cli

# scan the wireless networks
> scan
> scan_results
# to associate with <my-ssid>, add the network, set the credentials and enable it
> add_network
0
> set_network 0 ssid "<my-ssid>"
> set_network 0 psk "<passphrase>"
> enable_network 0
# check for something like:
# <2>CTRL-EVENT-CONNECTED - Connection to 00:00:00:00:00:00 completed (reauth) [id=0 id_str=]

# now save the config to the file previously created
> save_config
# OK
> quit
```

The file `/etc/wpa_supplicant/wpa_supplicant_<your-interface>.conf` should have been updated with a network block 
for that wireless network. The network interface should be UP in both places in the output of the `ip link` command:
```shell
$ ip link show
#                                        here                                 here
#                                        |                                    |
# <your-interface>: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DORMANT qlen 1000
#   link/ether 00:60:64:37:4a:30 brd ff:ff:ff:ff:ff:ff
```

Now your network card/something is connected and authenticated to the wireless network, but you don't have an IP yet,
nor a valid route in the routing table or DNS servers set. The fastest way to this is to use a DHCP client as follows:
```shell
$ dhcpcd <your-interface>
```

### Wireless connection at boot

Several systemd units are provided from both `wpa_supplicant` and `dhcpcd` to automate connection at boot.

For `wpa_supplicant` the unit _wpa_supplicant@interface.service_ accepts the interface name as an argument 
and starts the _wpa_supplicant_ daemon for this interface. It reads a `/etc/wpa_supplicant/wpa_supplicant-<your-interface>.conf` 
configuration file (created previously if the steps above are followed)

Copy the template file and enable it (it could be in different places based on your system, but this should work):
```shell
$ cp /usr/lib/systemd/system/wpa_supplicant@.service /usr/lib/systemd/system/wpa_supplicant@<your-interface>.service
$ systemctl enable wpa_supplicant@<your-interface>
```

For the DHCP client is even easier, just enable the _dhcpcd_ systemd unit. Note that in some cases it could be necessary
to create and activate an interface-specific unit (template at /usr/lib/systemd/system/dhcp@.service_).  
```shell
$ systemctl enable dhcpcd
```

Reboot and check if everything works.