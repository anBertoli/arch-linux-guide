#!/bin/bash
set -e 

DEVICE="wlan0"
SSID="TISCALI-Andrea"
PASSPHRASE="DK3U7B43CY"

DEV_FILE="/dev/nvme01"
DEV_FILE_EFI="/dev/nvme01"
DEV_FILE_ROOT="/dev/nvme01"
DEV_FILE_SWAP="/dev/nvme01"

BOOTLOADER_ID="arch-andrea"
PASSWORD="AndreaLinux"                       
USER=andrea


#######################################################################
######## BOOT FROM INSTALLATION MEDIUM ################################
#######################################################################

### check we have booted in UEFI mode
if [ -z "$(ls -A /sys/firmware/efi/efivars)" ]; then
    echo "Empty /sys/firmware/efi/efivars"
    exit 1
fi

### set keyboard layout
ls /usr/share/kbd/keymaps/**/*.map.gz | grep it
loadkeys /usr/share/kbd/keymaps/i386/qwerty/it

### connect to internet using non-interactive CLI
iwctl device list
iwctl station $DEVICE scan
iwctl station $DEVICE get-networks
iwctl --passphrase "$PASSPHRASE" station "$DEVICE" connect "$SSID"
ping -i 10 8.8.8.8

### sync the machine clock
timedatectl set-ntp true

### remount partitions
mount --mkdir $DEV_FILE_EFI /mnt/boot
mount --mkdir $DEV_FILE_ROOT /mnt
swapon $DEV_FILE_SWAP


#######################################################################
######## OS INSTALLATION ##############################################
#######################################################################

### optimizie downloads
reflector \
  --download-timeout 60 \
  --country Italy \
  --age 12 \
  --protocol https \
  --sort rate \
  --save /etc/pacman.d/mirrorlist

### install basic packages
pacman -Sy

pacstrap /mnt \     # /mnt = ROOT partition
    linux \
    linux-firmware \  
    base \
    sudo \         
    networkmanager
    gcc \
    git \
    make \
    vim 

### persist mounts
genfstab -U /mnt >> /mnt/etc/fstab


#######################################################################
######## BOOT LOADER (GRUB) INSTALLATION ##############################
#######################################################################
# 📝️ Inside the chroot at the mount point of the root partition (/mnt/)

arch-chroot /mnt

### install microcode updates
pacman -S amd-ucode

### install GRUB
pacman -S grub efibootmgr
efibootmgr -v

mount --mkdir $DEV_FILE_EFI /boot
grub-install \
    --target=x86_64-efi \
    --bootloader-id=$BOOTLOADER_ID \
    --efi-directory=/boot

### save GRUB conf
grub-mkconfig -o /boot/grub/grub.cfg


#######################################################################
######## OS CONFIGURATION ##############################################
#######################################################################
# 📝️ Inside the chroot at the mount point of the root partition (/mnt/)

### localization (timezone)
ls -alh /usr/share/zoneinfo
ln -sf /usr/share/zoneinfo/<region>/<city> /etc/localtime
hwclock --systohc # generate /etc/adjtime

### localization (language)
vim /etc/locale.gen   # uncomment chosen languages 
locale-gen            # generate and save locale files

touch /etc/locale.conf
echo "LANG=en_US.UTF-8" > /etc/locale.conf 

### localization (keyboard)
touch /etc/vconsole.conf
echo "KEYMAP=it" > /etc/vconsole.conf 

### network
pacman -S networkmanager
systemctl stop wpa_supplicant
systemctl disable wpa_supplicant
systemctl enable NetworkManager

echo "andrea-<machine>" >> /etc/hostname
echo "\
127.0.0.1        localhost
::1              localhost
127.0.1.1        andrea-<machine>" > /etc/hosts

### users and security
useradd -m -G wheel $USER
echo $PASSWORD | passwd --stdin             # root
echo $PASSWORD | passwd --stdin $USER       # user

sed -i '/%wheel ALL=(ALL) ALL/s/^#//g' /etc/sudoers

### done
exit
umount -R /mnt    
reboot



#######################################################################
######## GRAPHICS #####################################################
#######################################################################

### window server
pacman -S xorg-server

### grphic card drivers
pacman -S nvidia nvidia-utils

### desktop enviroment
pacman -S plasma
systemctl enable sddm

