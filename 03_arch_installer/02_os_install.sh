#!/bin/bash
set -e
source config.sh
source print.sh

print_banner "OS Installation (3/4)"
print_text "This section will guide you through the OS installation."

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

prompt_continue "Continue?"

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

prompt_continue "Continue?"

### remount partitions
set -x
mount --mkdir "$DISK_PART_EFI_DEV_FILE" /mnt/boot
mount --mkdir "$DISK_PART_ROOT_DEV_FILE" /mnt
swapon "$DISK_PART_SWAP_DEV_FILE"
set +x

prompt_continue "Continue?"

#######################################################################
######## OS INSTALLATION ##############################################
#######################################################################
print_header_section "OS Installation"

### optimize downloads
print_checklist_item "setting mirrors"
set -x
reflector \
  --download-timeout 60 \
  --country Italy \
  --age 12 \
  --protocol https \
  --sort rate \
  --save /etc/pacman.d/mirrorlist
set +x

### install basic packages
print_checklist_item "installing basic packages"
set -x
pacman --noconfirm -Sy
pacstrap /mnt \
    linux \
    linux-firmware \
    base \
    sudo \
    networkmanager \
    gcc \
    git \
    make \
    docker \
    vim \
    curl
set +x

### persist mounts
print_checklist_item "persist mounts with genfstab"
set -x
genfstab -U /mnt >> /mnt/etc/fstab
set +x

prompt_continue "Continue?"

#######################################################################
######## BOOT LOADER (GRUB) INSTALLATION ##############################
#######################################################################
# 📝️ Inside the chroot at the mount point of the root partition (/mnt/)
print_header_section "GRUB Installation (boot loader)"

### install microcode updates
print_checklist_item "installing microcode"
set -x
arch-chroot /mnt pacman --noconfirm -S amd-ucode
set +x

### install GRUB
print_checklist_item "installing grub and efibootmgr"
set -x
arch-chroot /mnt pacman --noconfirm -S grub efibootmgr
arch-chroot /mnt efibootmgr -v

arch-chroot /mnt mount --mkdir "$DISK_PART_EFI_DEV_FILE" /boot
arch-chroot /mnt grub-install \
    --target=x86_64-efi \
    --bootloader-id="$BOOTLOADER_ID" \
    --efi-directory=/boot

set +x

### save GRUB conf
print_checklist_item "saving GRUB conf"
set -x
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
set +x

prompt_continue "Continue?"

#######################################################################
######## OS CONFIGURATION ##############################################
#######################################################################
# 📝️ Inside the chroot at the mount point of the root partition (/mnt/)
print_header_section "OS configuration"

### localization (timezone)
print_checklist_item "setting timezone"
set -x
arch-chroot /mnt ls -alh /usr/share/zoneinfo
arch-chroot /mnt ln -sf /usr/share/zoneinfo/<region>/<city> /etc/localtime
arch-chroot /mnt hwclock --systohc # generate /etc/adjtime
set +x

### localization (language)
print_checklist_item "setting and persisting language"
set -x
arch-chroot /mnt vim /etc/locale.gen   # uncomment chosen languages
arch-chroot /mnt locale-gen            # generate and save locale files

arch-chroot /mnt touch /etc/locale.conf
arch-chroot /mnt echo "LANG=en_US.UTF-8" > /etc/locale.conf
set +x


### localization (keyboard)
print_checklist_item "setting and persisting keyboard"
set -x
arch-chroot /mnt touch /etc/vconsole.conf
arch-chroot /mnt echo "KEYMAP=it" > /etc/vconsole.conf
set +x

### network
print_checklist_item "enabling network manager"
set -x
arch-chroot /mnt systemctl stop wpa_supplicant
arch-chroot /mnt systemctl disable wpa_supplicant
arch-chroot /mnt systemctl enable NetworkManager
set +x

print_checklist_item "generating /etc/hostname and /etc/hosts"
set -x
arch-chroot /mnt echo "andrea-<machine>" >> /etc/hostname
arch-chroot /mnt echo "\
127.0.0.1        localhost
::1              localhost
127.0.1.1        andrea-<machine>" > /etc/hosts
set +x

### users and security
print_header_section "setting users and security confs"
print_checklist_item "adding user"
set -x
arch-chroot /mnt useradd -m -G wheel "$USER"
set +x

print_checklist_item "setting root and user passwords"
set -x
arch-chroot /mnt echo "$USER_PASSWORD" | passwd --stdin                    # root
arch-chroot /mnt echo "$USER_PASSWORD" | passwd --stdin "$USER_NAME"       # user
set +x

print_checklist_item "adding user to wheel (admins)"
set -x
arch-chroot /mnt sed -i '/%wheel ALL=(ALL) ALL/s/^#//g' /etc/sudoers
arch-chroot cat /etc/sudoers
set +x

prompt_continue "Continue?"

#######################################################################
######## GRAPHICS #####################################################
#######################################################################
print_header_section "Graphics configuration"

### window server
print_checklist_item "installing xorg"
set -x
arch-chroot /mnt pacman --noconfirm -S xorg-server
set +x

### graphic card drivers
print_checklist_item "installing graphic card drivers"
set -x
arch-chroot /mnt pacman --noconfirm -S nvidia nvidia-utils
set +x

### desktop environment
print_checklist_item "installing plasma (desktop)"
set -x
arch-chroot /mnt pacman --noconfirm -S plasma
arch-chroot /mnt systemctl enable sddm
set +x

### end
print_header_section "Checkpoint"
print_text "
${BOLD_INTENSE_GREEN}OS ready!${BOLD_INTENSE_WHITE}

If you want to automatically install user space programs and
utils continue to the next section.

To do so start the ./03_os_custom.sh script in the chroot so:
${BOLD_INTENSE_GREEN}arch-chroot /mnt ./03_os_custom.sh ${BOLD_INTENSE_WHITE}.

Exiting.
"