#!/bin/bash
set -e

source config.sh
source print.sh

print_banner "Init installation"
print_text "This section allows you to (re)start from different points in the installation process.
Available options:
- ${BOLD_INTENSE_GREEN}1${BOLD_INTENSE_WHITE}: starting installation from scratch (1/4)
- ${BOLD_INTENSE_GREEN}2${BOLD_INTENSE_WHITE}: resuming installation from pre-installation script (2/4)
- ${BOLD_INTENSE_GREEN}3${BOLD_INTENSE_WHITE}: resuming installation from os installation script (3/4)
- ${BOLD_INTENSE_GREEN}4${BOLD_INTENSE_WHITE}: resuming installation from os userspace customization (4/4)
- ${BOLD_INTENSE_GREEN}conf${BOLD_INTENSE_WHITE}: regenerate configs

If you resume the installation from another point and the config file is not present you must
regenerate it. To do so choose the 'conf' option.
"

case "$1" in
  "conf")
     ./00_config_init.sh
     ;;
  "" | "1")
    prompt_continue "Starting installation from scratch (1/4). Proceed?"
    ./00_config_init.sh
    ./01_pre_install.sh
    ./02_os_install.sh
    ./03_os_custom.sh
    ;;
  "2"):
    prompt_continue "Resuming installation from pre-installation script (2/4). Proceed?"
   ./01_pre_install.sh
   ./02_os_install.sh
   ./03_os_custom.sh
    ;;
  "3")
     prompt_continue "Resuming installation from os installation script (3/4). Proceed?"
    ./02_os_install.sh
    ./03_os_custom.sh
    ;;
  "4")
     prompt_continue "Resuming installation from os userspace customization (3/4). Proceed?"
    ./03_os_custom.sh
    ;;
  *)
    print_text "Invalid choice. Aborting."
esac

