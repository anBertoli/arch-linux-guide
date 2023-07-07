#!/bin/bash
set -e
source config.sh
source print.sh

print_banner "Pre installation configuration (2/4)"
print_text "This section will prepare the disk to install the OS."

# load configs
check_conf_file
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
print_text "Setting /usr/share/kbd/keymaps/i386/qwerty/it layout"
set -x
find /usr/share/kbd/keymaps -type f -name "*.map.gz" | grep it
loadkeys /usr/share/kbd/keymaps/i386/qwerty/it
set +x

prompt_continue "\nContinue?"

### connect to internet using non-interactive CLI
print_checklist_item "connecting via wifi device"
set -x
iwctl device list
iwctl station "$WIFI_DEVICE" scan
iwctl station "$WIFI_DEVICE" get-networks
iwctl --passphrase "$WIFI_PASSPHRASE" station "$WIFI_DEVICE" connect "$WIFI_SSID"
set +x

print_text "Waiting for connection.. (10 secs)"
set -x
sleep 10
ping -c 5 -w 10 8.8.8.8
set +x

### sync the machine clock using the NTP time protocol
print_checklist_item "sync time (NTP)"
set -x
timedatectl set-ntp true
set +x

prompt_continue "\nContinue?"

#######################################################################
######## DISK PREPARATION #############################################
#######################################################################
print_header_section "Disk partitioning"

### delete all partitions
print_checklist_item "erasing disk"
print_text "Current disk state:\n $(sgdisk -p "$DISK_DEV_FILE")"
prompt_continue "Disk will be erased, to you want to continue?"

print_checklist_item "unmounting filesystem /mnt"
set -x
umount -R /mnt
set +x

set -x
sgdisk --clear "$DISK_DEV_FILE"
sgdisk -p "$DISK_DEV_FILE"
set +x

### start = 0, means next starting point
print_checklist_item "partitioning disk"
set -x
sgdisk -n 1:0:+1G -t 1:ef00 -g "$DISK_DEV_FILE" # EFI
sgdisk -n 2:0:+10G -t 2:8200 -g "$DISK_DEV_FILE" # SWAP
sgdisk -n 3:0:+500G -t 3:8300 -g "$DISK_DEV_FILE" # ROOT
sgdisk -p "$DISK_DEV_FILE"
set +x

### format partitions with fs
print_checklist_item "creating filesystem within partitions"
set -x
mkfs.fat -F32 "$DISK_PART_EFI_DEV_FILE" # EFI
mkfs.ext4 "$DISK_PART_ROOT_DEV_FILE" # ROOT
mkswap "$DISK_PART_SWAP_DEV_FILE" # SWAP
set +x

### mount partitions, for SWAP, just tell Linux to use it
print_checklist_item "mounting filesystems"
set -x
mount --mkdir "$DISK_PART_EFI_DEV_FILE" /mnt/boot
mount --mkdir "$DISK_PART_ROOT_DEV_FILE" /mnt
set +x

print_checklist_item "enabling swap space"
set -x
swapon "$DISK_PART_SWAP_DEV_FILE"
set +x

prompt_continue "Continue?"

#######################################################################
######## DUAL BOOT CHECKPOINT #########################################
#######################################################################

print_header_section "Checkpoint"
print_text "
Exit and install ${BOLD_INTENSE_GREEN}Windows${BOLD_INTENSE_WHITE} at this point if you want
to set up a dual boot machine. Use remaining free space on the disk
to install Windows. The EFI partition will be shared.

If you want to continue execute the ${BOLD_INTENSE_GREEN}./02_os_install.sh${BOLD_INTENSE_WHITE} script.

Note that if you exit and then come back to start the next script,
then the config file may be lost. In that case regenerate it by
executing the ${BOLD_INTENSE_GREEN}./00_config_init.sh${BOLD_INTENSE_WHITE} script.

Exiting.
"