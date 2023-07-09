#!/bin/bash
set -e 

print_banner "OS user space customization (4/4)"
print_text "This section will guide you through the customization of your OS."

# load configs
check_conf_file
source ./config.gen.sh
check_vars


### chroot into ROOT, install programs
arch-chroot /mnt/ /bin/bash -c "cd $(pwd) && ./03_os_custom_chroot.sh"
