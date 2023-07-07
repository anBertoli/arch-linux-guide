#!/bin/bash
set -e 

print_header "OS installation
(3/4)"

# load configs
source ./config.gen.sh
check_vars


#######################################################################
######## BOOT FROM INSTALLATION MEDIUM ################################
#######################################################################

print_header_section "Preliminary operations"

### check we have booted in UEFI mode
print_header_par "checking correct UEFI boot"
if [ -z "$(ls -A /sys/firmware/efi/efivars)" ]; then
    echo "Empty /sys/firmware/efi/efivars"
    exit 1
fi

### set keyboard layout
print_header_par "setting IT keyboard layout"
ls -alh /usr/share/kbd/keymaps/**/*.map.gz | grep it
loadkeys /usr/share/kbd/keymaps/i386/qwerty/it

### connect to internet using non-interactive CLI
print_header_par "connecting via wifi device"
iwctl device list
iwctl station "$WIFI_DEVICE" scan
iwctl station "$WIFI_DEVICE" get-networks
iwctl --passphrase "$WIFI_PASSPHRASE" station "$WIFI_DEVICE" connect "$WIFI_SSID"
ping -i 1 8.8.8.8

### sync the machine clock using the NTP time protocol
timedatectl set-ntp true

### remount partitions
mount --mkdir "$DISK_PART_EFI_DEV_FILE" /mnt/boot
mount --mkdir "$DISK_PART_ROOT_DEV_FILE" /mnt
swapon "$DISK_PART_SWAP_DEV_FILE"


#######################################################################
######## OS INSTALLATION ##############################################
#######################################################################
print_header_section "OS Installation"

### optimize downloads
print_header_par "setting mirrors"
reflector \
  --download-timeout 60 \
  --country Italy \
  --age 12 \
  --protocol https \
  --sort rate \
  --save /etc/pacman.d/mirrorlist

### install basic packages
print_header_par "installing basic packages"
pacman -Sy

pacstrap /mnt \     # /mnt = ROOT partition
    linux \
    linux-firmware \
    base \
    sudo \
    networkmanager \
    gcc \
    git \
    make \
    vim \
    curl

### persist mounts
print_header_par "persist mounts with genfstab"
genfstab -U /mnt >> /mnt/etc/fstab


#######################################################################
######## BOOT LOADER (GRUB) INSTALLATION ##############################
#######################################################################
# 📝️ Inside the chroot at the mount point of the root partition (/mnt/)

### install microcode updates
arch-chroot /mnt pacman -S amd-ucode

### install GRUB
arch-chroot /mnt pacman -S grub efibootmgr
arch-chroot /mnt efibootmgr -v

arch-chroot /mnt mount --mkdir $DISK_PART_EFI_DEV_FILE /boot
arch-chroot /mnt grub-install \
    --target=x86_64-efi \
    --bootloader-id=$BOOTLOADER_ID \
    --efi-directory=/boot

### save GRUB conf
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg


#######################################################################
######## OS CONFIGURATION ##############################################
#######################################################################
# 📝️ Inside the chroot at the mount point of the root partition (/mnt/)

### localization (timezone)
arch-chroot /mnt ls -alh /usr/share/zoneinfo
arch-chroot /mnt ln -sf /usr/share/zoneinfo/<region>/<city> /etc/localtime
arch-chroot /mnt hwclock --systohc # generate /etc/adjtime

### localization (language)
arch-chroot /mnt vim /etc/locale.gen   # uncomment chosen languages
arch-chroot /mnt locale-gen            # generate and save locale files

arch-chroot /mnt touch /etc/locale.conf
arch-chroot /mnt echo "LANG=en_US.UTF-8" > /etc/locale.conf

### localization (keyboard)
arch-chroot /mnt touch /etc/vconsole.conf
arch-chroot /mnt echo "KEYMAP=it" > /etc/vconsole.conf

### network
arch-chroot /mnt pacman -S networkmanager
arch-chroot /mnt systemctl stop wpa_supplicant
arch-chroot /mnt systemctl disable wpa_supplicant
arch-chroot /mnt systemctl enable NetworkManager

arch-chroot /mnt echo "andrea-<machine>" >> /etc/hostname
arch-chroot /mnt echo "\
127.0.0.1        localhost
::1              localhost
127.0.1.1        andrea-<machine>" > /etc/hosts

### users and security
arch-chroot /mnt useradd -m -G wheel $USER
arch-chroot /mnt echo "$USER_PASSWORD" | passwd --stdin                    # root
arch-chroot /mnt echo "$USER_PASSWORD" | passwd --stdin "$USER_NAME"       # user

arch-chroot /mnt sed -i '/%wheel ALL=(ALL) ALL/s/^#//g' /etc/sudoers

#######################################################################
######## GRAPHICS #####################################################
#######################################################################

### window server
arch-chroot /mnt pacman -S xorg-server

### grphic card drivers
arch-chroot /mnt pacman -S nvidia nvidia-utils

### desktop enviroment
arch-chroot /mnt pacman -S plasma
arch-chroot /mnt systemctl enable sddm

### done
umount -R /mnt
reboot