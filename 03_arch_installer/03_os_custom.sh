#!/bin/bash
set -e 

source ./config.sh
source ./print.sh

print_banner "OS user space customization (4/4)"
print_text "This section will guide you through the customization of your OS."

# load configs
check_conf_file
source ./config.gen.sh
check_vars

### chroot into ROOT partition (where OS will be installed)
print_checklist_item "copying scripts into user home partition"
set -x
rm -rf "/mnt/home/${USER_NAME}/arch-installer"
cp -R "$(pwd)/.." "/mnt/home/${USER_NAME}/arch-installer"
set +x

print_text "
Copied to '/mnt/home/${USER_NAME}/arch-installer'
Folder contents ('/mnt/home/${USER_NAME}/arch-installer'):
\n$(ls -alh "/mnt/home/${USER_NAME}/arch-installer")"

prompt_continue "Continue?"

#arch-chroot -u "${USER_NAME}" /mnt /bin/bash -c "
arch-chroot /mnt /bin/bash -c "
cd /home/${USER_NAME}/arch-installer/03_arch_installer
./03_os_custom_chroot.sh
"

#print_text "Cleaning"
#set -x
#rm -rf "/mnt/home/${USER_NAME}/arch-installer"
#set +x