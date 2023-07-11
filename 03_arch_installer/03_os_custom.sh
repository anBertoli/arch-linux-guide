#!/bin/bash
set -e 

source ./config.sh
source ./print.sh

print_banner "OS user space customization (4/4)"
print_text "This section will guide you through the customization of your OS."

### load configs
check_conf_file
source ./config.gen.sh
AUTO_YES=$1
check_vars


#######################################################################
######## CHROOT AND INSTALL THINGS ####################################
#######################################################################
print_checklist_item "copying scripts into user home"

set -x
rm -rf "/mnt/home/${USER_NAME}/arch-installer"
cp -R "$(pwd)/.." "/mnt/home/${USER_NAME}/arch-installer"
set +x

print_text "
Copied to '/mnt/home/${USER_NAME}/arch-installer'
Folder contents ('/mnt/home/${USER_NAME}/arch-installer'):
\n$(ls -alh "/mnt/home/${USER_NAME}/arch-installer")"

prompt_continue "Continue?" "$AUTO_YES"

arch-chroot /mnt sudo -u "${USER_NAME}" /bin/bash -c "
set -e
cd /home/${USER_NAME}/arch-installer/03_arch_installer
./03_os_custom_chroot.sh ${AUTO_YES}
"

print_checklist_item "cleaning scripts file into user home"
set -x
rm -rf "/mnt/home/${USER_NAME}/arch-installer"
set +x



#######################################################################
######## END CHECKPOINT CONFIGURATION #################################
#######################################################################
print_header_section "Checkpoint"
print_text "
${BOLD_INTENSE_GREEN}Success! :)${BOLD_INTENSE_WHITE}

All done, just reboot the system and use it or
hang around before rebooting.

Exiting.
"