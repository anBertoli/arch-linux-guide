#!/bin/bash
set -e
source ./config.sh
source ./print.sh

# load configs
check_conf_file
source ./config.gen.sh
check_vars



#######################################################################
######## BOOT LOADER (GRUB) INSTALLATION ##############################
#######################################################################
# 📝️ Inside the chroot at the mount point of the root partition (/mnt/)
print_header_section "GRUB Installation (boot loader)"

### install microcode updates
print_checklist_item "installing microcode"
set -x
pacman --noconfirm -S amd-ucode
set +x

### install GRUB
print_checklist_item "installing grub and efibootmgr"
print_text "Current EFIBOOT state:\n\n$(efibootmgr -v)"
set -x
pacman --noconfirm -S grub efibootmgr
#mount --mkdir "$DISK_PART_EFI_DEV_FILE" /boot
grub-install \
    --target=x86_64-efi \
    --bootloader-id="$BOOTLOADER_ID" \
    --efi-directory=/boot

set +x

### save GRUB conf
print_checklist_item "saving GRUB conf"
set -x
grub-mkconfig -o /boot/grub/grub.cfg
set +x

prompt_continue "Continue?"

#######################################################################
######## LOCALE & KEYBOARD CONFIGURATION ##############################
#######################################################################
# 📝️ Inside the chroot at the mount point of the root partition (/mnt/)
print_header_section "Local & keyboard configuration"

### localization (timezone)
print_checklist_item "setting timezone"
set -x
find /usr/share/zoneinfo -type f | grep Rome
ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime
hwclock --systohc # generate /etc/adjtime
set +x

### localization (language)
print_checklist_item "setting and persisting language"
set -x
LOCALE_GEN="en_US.UTF-8"
LOCALE_CONF="LANG=en_US.UTF-8"

# uncomment chosen language then
# generate and save locale files
sed -i "/${LOCALE_GEN}/s/^#//g" /etc/locale.gen
if ! grep "^${LOCALE_GEN}" /etc/locale.gen;
then
  print_text "/etc/locale.gen error"
  print_text "$(grep "${LOCALE_GEN}" /etc/locale.gen)"
  exit 1
fi

locale-gen
touch /etc/locale.conf
echo "${LOCALE_CONF}" > /etc/locale.conf
set +x

### localization (keyboard)
print_checklist_item "setting and persisting keyboard"
set -x
touch /etc/vconsole.conf
echo "KEYMAP=it" > /etc/vconsole.conf
set +x

#######################################################################
######## OS NETWORK CONFIGURATION #####################################
#######################################################################
# 📝️ Inside the chroot at the mount point of the root partition (/mnt/)
print_header_section "Network configuration"

### network
print_checklist_item "enabling network manager"
set -x
systemctl disable wpa_supplicant
systemctl enable NetworkManager
set +x

print_checklist_item "generating /etc/hostname and /etc/hosts"
set -x
# TODO: add another var?
echo "${USER_NAME}" >> /etc/hostname
echo "\
127.0.0.1        localhost
::1              localhost
127.0.1.1        ${USER_NAME}" > /etc/hosts
set +x


#######################################################################
######## USERS & SECURITY CONFIGURATION ###############################
#######################################################################
# 📝️ Inside the chroot at the mount point of the root partition (/mnt/)
print_header_section "Users and security"

### users and security
print_checklist_item "adding user ${USER_NAME}"
set -x
useradd -m -G wheel "$USER_NAME"
set +x

print_checklist_item "setting root and user passwords"
set -x
echo "root:$USER_PASSWORD" | chpasswd                 # root
echo "$USER_NAME:$USER_PASSWORD" | chpasswd           # user
set +x

print_checklist_item "adding user to wheel (admins)"
set -x
sed -i '/%wheel ALL=(ALL) ALL/s/^# //g' /etc/sudoers
if ! grep "^%wheel ALL=(ALL) ALL" /etc/sudoers;
then
  print_text "/etc/locale.gen error"
  print_text "$(grep "%wheel ALL=(ALL) ALL" /etc/sudoers)"
  exit 1
fi
set +x

print_text "Reading '/etc/sudoers' file:\n\n$(cat /etc/sudoers)"

prompt_continue "Continue?"

#######################################################################
######## GRAPHICS #####################################################
#######################################################################
print_header_section "Graphics configuration"

### window server
print_checklist_item "installing xorg"
set -x
pacman --noconfirm -S xorg-server
set +x

### graphic card drivers
print_checklist_item "installing graphic card drivers"
set -x
pacman --noconfirm -S nvidia nvidia-utils
set +x

### desktop environment
print_checklist_item "installing plasma (desktop)"
set -x
pacman --noconfirm -S plasma
systemctl enable sddm
set +x

### end
print_header_section "Checkpoint"
print_text "
${BOLD_INTENSE_GREEN}OS ready!${BOLD_INTENSE_WHITE}

If you want to automatically install user space programs and
utils continue to the next section.

To do so start the ./03_os_custom.sh script: ${BOLD_INTENSE_GREEN}./03_os_custom.sh${BOLD_INTENSE_WHITE}.

Exiting.
"