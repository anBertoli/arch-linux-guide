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


### chroot into root partition (where OS is installed),
### then install programs an/or configure things
arch-chroot -u "${USER_NAME}" /mnt/ /bin/bash -c "cd $(pwd) && ./03_os_custom_chroot.sh"
