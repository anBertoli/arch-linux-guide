#!/bin/bash
set -e
source config.sh
source print.sh

print_header "Pre installation configuration"

# load configs
source ./config.gen.sh
check_vars

#######################################################################
######## BOOT FROM INSTALLATION MEDIUM ################################
#######################################################################
print_header_section "Preliminary operations"

# check we have booted in UEFI mode
print_header_par "checking correct UEFI boot"
if [ -z "$(ls -A /sys/firmware/efi/efivars)" ]; then
    echo "Empty /sys/firmware/efi/efivars"
    exit 1
fi

# set keyboard layout
print_header_par "setting IT keyboard layout"
ls -alh /usr/share/kbd/keymaps/**/*.map.gz | grep it
loadkeys /usr/share/kbd/keymaps/i386/qwerty/it

# connect to internet using non-interactive CLI
print_header_par "connecting via wifi device"
iwctl device list
iwctl station "$WIFI_DEVICE" scan
iwctl station "$WIFI_DEVICE" get-networks
iwctl --passphrase "$WIFI_PASSPHRASE" station "$WIFI_DEVICE" connect "$WIFI_SSID"
ping -i 1 8.8.8.8

# sync the machine clock using the NTP time protocol
timedatectl set-ntp true


#######################################################################
######## DISK PREPARATION #############################################
#######################################################################
print_header_section "Disk partitioning"

# list partitions then delete all of them
print_header_par "erasing disk"
print_text "Current disk state:\n\n$(sgdisk -p "$DISK_DEV_FILE")"
prompt_continue "Disk will be erased, to you want to continue?"

set -x
sgdisk --clear "$DISK_DEV_FILE"
sgdisk -p "$DISK_DEV_FILE"
set +x

# start = 0, means next starting point
print_header_par "partitioning disk"
sgdisk -n 1:0:+1G -t 1:ef00 -g "$DISK_DEV_FILE" # EFI
sgdisk -n 2:0:+10G -t 2:8200 -g "$DISK_DEV_FILE" # SWAP
sgdisk -n 3:0:+500G -t 3:8300 -g "$DISK_DEV_FILE" # ROOT
print_text "$(sgdisk -p "$DISK_DEV_FILE")"

# format EFI partition (FAT32)
# format ROOT partition (EXT4)
# format SWAP partition
print_header_par "creating filesystem within partitions"
mkfs.fat -F32 "$DISK_PART_EFI_DEV_FILE"
mkfs.ext4 "$DISK_PART_ROOT_DEV_FILE"
mkswap "$DISK_PART_SWAP_DEV_FILE"

# mount the EFI partition
# mount ROOT partition
# don't mount SWAP partition, just tell Linux to use it
print_header_par "mounting filesystems"
mount --mkdir "$DISK_PART_EFI_DEV_FILE" /mnt/boot
mount --mkdir "$DISK_PART_ROOT_DEV_FILE" /mnt
swapon "$DISK_PART_SWAP_DEV_FILE"


#######################################################################
######## DUAL BOOT CHECKPOINT #########################################
#######################################################################

print_header_section "dual boot checkpoint"
echo -e "
Exit and install ${BOLD_INTENSE_GREEN}Windows${RESET} at this point if you want
to dual boot. Use remaining free space on the disk
to install windows. The EFI partition will be shared.

To stop the installer abort at the next prompt.
"

prompt_abort "Do you want to stop the installer? "
