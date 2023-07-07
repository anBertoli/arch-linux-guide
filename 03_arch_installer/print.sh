#!/bin/bash
set -e

BOLD_INTENSE_GREEN='\033[1;92m'
BOLD_INTENSE_PURPLE='\033[1;95m'
BOLD_INTENSE_RED='\033[1;91m'
BOLD_INTENSE_CYAN='\033[1;96m'
BOLD_INTENSE_BLUE='\033[1;94m'
BOLD_INTENSE_GREEN='\033[1;92m'
BOLD_INTENSE_WHITE='\033[1;97m'
NORMAL_INTENSE_GREEN='\033[0;92m'
RESET='\033[0m'

function print_banner() {
  echo -ne "${RESET}
------------------------------------
${BOLD_INTENSE_GREEN}
 █████╗ ██████╗  ██████╗██╗  ██╗    ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗
  ██╔══██╗██╔══██╗██╔════╝██║  ██║    ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗
  ███████║██████╔╝██║     ███████║    ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝     ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝
  ██╔══██║██╔══██╗██║     ██╔══██║    ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗     ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══╝  ██╔══██╗
  ██║  ██║██║  ██║╚██████╗██║  ██║    ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗    ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗███████╗██║  ██║
  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝
  $1
${BOLD_INTENSE_WHITE}
------------------------------------
${RESET}
"
}

function print_header_section() {
  echo -ne "${RESET}${BOLD_INTENSE_WHITE}
------------------------------------
${BOLD_INTENSE_GREEN}${1}${RESET}${BOLD_INTENSE_WHITE}
------------------------------------
${RESET}
"
}

function print_checklist_item() {
  echo -ne "${RESET}- ${BOLD_INTENSE_GREEN}${1}${RESET}
"
}

function print_text() {
  echo -ne "${RESET}${BOLD_INTENSE_WHITE}${1}${RESET}
"
}

function prompt_continue() {
  echo
  while true; do
      read -p "$(echo -e "${BOLD_INTENSE_WHITE}$1${RESET} [y/n] ")" YN
      case $YN in
          [Yy]* ) echo; return;;
          [Nn]* ) echo "Exiting."; exit 1;;
          * ) echo "Please answer yes or no.";;
      esac
  done
}

function prompt_abort() {
  echo
  while true; do
      read -p "$(echo -e "${BOLD_INTENSE_WHITE}$1${RESET} [y/n] ")" YN
      case $YN in
          [Yy]* ) echo;  echo "Exiting."; exit 1;;
          [Nn]* ) return;;
          * ) echo "Please answer yes or no.";;
      esac
  done
}