#!/bin/bash
set -e

source config.sh
source print.sh
AUTO_YES=no

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

read -r -p "Choose step to start from: " STEP
case "$STEP" in
  "conf")
    prompt_continue "Regenerating configs only. Proceed?"
    prompt_auto_yes
    ./00_config_init.sh "$AUTO_YES"
    ;;
  "" | "1")
    prompt_continue "Starting installation from scratch (1/4). Proceed?"
    prompt_auto_yes
    ./00_config_init.sh "$AUTO_YES"
    ./01_pre_install.sh "$AUTO_YES"
    ./02_os_install.sh "$AUTO_YES"
    ./03_os_custom.sh "$AUTO_YES"
    ;;
  "2"):
    prompt_continue "Resuming installation from pre-installation script (2/4). Proceed?"
    prompt_auto_yes
    ./01_pre_install.sh "$AUTO_YES"
    ./02_os_install.sh "$AUTO_YES"
    ./03_os_custom.sh "$AUTO_YES"
    ;;
  "3")
    prompt_continue "Resuming installation from os installation script (3/4). Proceed?"
    prompt_auto_yes
    ./02_os_install.sh "$AUTO_YES"
    ./03_os_custom.sh "$AUTO_YES"
    ;;
  "4")
    prompt_continue "Resuming installation from os userspace customization (3/4). Proceed?"
    prompt_auto_yes
    ./03_os_custom.sh "$AUTO_YES"
    ;;
  *)
    print_text "Invalid choice. Aborting."
esac


function prompt_auto_yes() {
  echo
  while true; do
      read -p "$(echo -e "${BOLD_INTENSE_WHITE}Automatically proceed on everything?${RESET} [y/n] ")" YN
      case $YN in
          [Yy]* ) AUTO_YES=yes; return;;
          [Nn]* ) AUTO_YES=no; return;;
          * ) echo "Please answer yes or no.";;
      esac
  done
}