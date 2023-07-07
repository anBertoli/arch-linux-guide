#!/bin/bash
set -e
source config.sh
source print.sh

print_banner "Pre installation configuration (2/4)"

# load configs
source ./config.gen.sh
check_vars



#######################################################################
######## BOOT FROM INSTALLATION MEDIUM ################################
#######################################################################
print_header_section "Preliminary operations"

### check we have booted in UEFI mode
print_checklist_item "checking correct UEFI boot"
if [ -z "$(ls -A /sys/firmware/efi/efivars)" ]; then
    echo "Empty '/sys/firmware/efi/efivars'"
    exit 1
fi

### set keyboard layout
print_checklist_item "setting IT keyboard layout"
ls -alh /usr/share/kbd/keymaps/**/*.map.gz | grep it
loadkeys /usr/share/kbd/keymaps/i386/qwerty/it

### connect to internet using non-interactive CLI
print_checklist_item "connecting via wifi device"
iwctl device list
iwctl station "$WIFI_DEVICE" scan
iwctl station "$WIFI_DEVICE" get-networks
iwctl --passphrase "$WIFI_PASSPHRASE" station "$WIFI_DEVICE" connect "$WIFI_SSID"
ping -i 1 8.8.8.8

### sync the machine clock using the NTP time protocol
print_checklist_item "sync time (NTP)"
timedatectl set-ntp true



#######################################################################
######## DISK PREPARATION #############################################
#######################################################################
print_header_section "Disk partitioning"

print_checklist_item "erasing disk"
print_text "Current disk state:\n\n$(sgdisk -p "$DISK_DEV_FILE")"
prompt_continue "Disk will be erased, to you want to continue?"

# delete all partitions
sgdisk --clear "$DISK_DEV_FILE"
sgdisk -p "$DISK_DEV_FILE"

# start = 0, means next starting point
print_checklist_item "partitioning disk"
sgdisk -n 1:0:+1G -t 1:ef00 -g "$DISK_DEV_FILE" # EFI
sgdisk -n 2:0:+10G -t 2:8200 -g "$DISK_DEV_FILE" # SWAP
sgdisk -n 3:0:+500G -t 3:8300 -g "$DISK_DEV_FILE" # ROOT
print_text "$(sgdisk -p "$DISK_DEV_FILE")"

### format partitions with fs
print_checklist_item "creating filesystem within partitions"
mkfs.fat -F32 "$DISK_PART_EFI_DEV_FILE" # EFI
mkfs.ext4 "$DISK_PART_ROOT_DEV_FILE" # ROOT
mkswap "$DISK_PART_SWAP_DEV_FILE" # SWAP

### mount partitions, for SWAP, just tell Linux to use it
print_checklist_item "mounting filesystems"
mount --mkdir "$DISK_PART_EFI_DEV_FILE" /mnt/boot
mount --mkdir "$DISK_PART_ROOT_DEV_FILE" /mnt

print_checklist_item "enabling swap space"
swapon "$DISK_PART_SWAP_DEV_FILE"



#######################################################################
######## DUAL BOOT CHECKPOINT #########################################
#######################################################################

print_header_section "Dual boot checkpoint"
print_text "
Exit and install ${BOLD_INTENSE_GREEN}Windows${BOLD_INTENSE_WHITE} at this point if you want
to dual boot. Use remaining free space on the disk
to install Windows. The EFI partition will be shared.

To stop the installer abort at the next prompt.
"

prompt_abort "Do you want to stop the installer? "
