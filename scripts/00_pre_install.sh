#!/bin/bash
set -e 

DEVICE="wlan0"
SSID="TISCALI-Andrea"
PASSPHRASE="DK3U7B43CY"

DEV_FILE="/dev/nvme01"
DEV_FILE_EFI="/dev/nvme01"
DEV_FILE_ROOT="/dev/nvme01"
DEV_FILE_SWAP="/dev/nvme01"

######################## BOOT FROM INSTALLATION MEDIUM ########################

# check we have booted in UEFI mode
if [ -z "$(ls -A /sys/firmware/efi/efivars)" ]; then
    echo "Empty /sys/firmware/efi/efivars"
    exit 1
fi

# set keyboard layout
ls /usr/share/kbd/keymaps/**/*.map.gz | grep it
loadkeys /usr/share/kbd/keymaps/i386/qwerty/it

# connect to internet using non-interactive CLI
iwctl device list
iwctl station $DEVICE scan
iwctl station $DEVICE get-networks
iwctl --passphrase "$PASSPHRASE" station "$DEVICE" connect "$SSID"
ping -i 10 8.8.8.8

# sync the machine clock using the NTP time protocol
timedatectl set-ntp true


######################## DISK PREPARATION ########################

# list paritions than delete all of them
sgdisk --clear $DEV_FILE
sgdisk -p $DEV_FILE

# start = 0, means next starting point 
sgdisk -n 1:0:+1G -t 1:ef00 -g $DEV_FILE # EFI
sgdisk -n 2:0:+10G -t 2:8200 -g $DEV_FILE # SWAP
sgdisk -n 3:0:+500G -t 3:8300 -g $DEV_FILE # ROOT
sgdisk -p $DEV_FILE

# format EFI partition (FAT32)
# format ROOT partition (EXT4)
# format SWAP partition
mkfs.fat -F32 $DEV_FILE_EFI
mkfs.ext4 $DEV_FILE_ROOT
mkswap $DEV_FILE_SWAP

# mount the EFI partition
# mount ROOT partition
# don't mount SWAP partition, just tell Linux to use it
mount --mkdir $DEV_FILE_EFI /mnt/boot
mount --mkdir $DEV_FILE_ROOT /mnt
swapon $DEV_FILE_SWAP


### INSTALL WINDOWS AT THIS STEP IF YOU WANT TO  
### DUAL BOOT (USE REMAINING PART OF THE DISK),
### THE EFI PARTITION WILL BE SHARED.
