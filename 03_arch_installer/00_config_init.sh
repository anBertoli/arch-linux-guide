#!/bin/bash
set -e

source config.sh
source print.sh

print_banner "Config generation (1/4)"
print_text "This section will guide you through config generation."



#######################################################################
######## READ AND SAVE CONFIGS ##############################################
#######################################################################
print_header_section "Init configs"

### read in vars
print_checklist_item "Read in configs"
read_in_vars
check_vars

### confirm and save configs
print_checklist_item "Confirmation"
print_vars
prompt_continue "Do you confirm the values inserted?"

print_checklist_item "Write config file"
write_vars ./config.gen.sh
check_conf_file

### end
print_text "Config values written to '${BOLD_INTENSE_GREEN}./config.gen.sh${BOLD_INTENSE_WHITE}'.
To continue start the ${BOLD_INTENSE_GREEN}./01_pre_install.sh${BOLD_INTENSE_WHITE} script.

Exiting.
"

