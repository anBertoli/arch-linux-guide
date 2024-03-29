#!/bin/bash
set -e 

source ./config.sh
source ./print.sh

### load configs
check_conf_file
source ./config.gen.sh
AUTO_YES=$1
check_vars



#######################################################################
######## GET USER HOME ################################################
#######################################################################
print_header_section "Getting user home"
print_text "User HOME is '${HOME}'."
prompt_continue "Continue?" "$AUTO_YES"



#######################################################################
######## USERSPACE PROGRAMS ###########################################
#######################################################################
print_header_section "Programming languages and IDEs "
set -x
sudo pacman --noconfirm -Syu
set +x


### install go
print_checklist_item "install Go"
set -x
cd "${HOME}"
GO_VER=1.20
sudo rm -rf /usr/local/go

curl -L --output ./go${GO_VER}.linux-amd64.tar.gz https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf ./go${GO_VER}.linux-amd64.tar.gz
rm ./go${GO_VER}.linux-amd64.tar.gz

echo "export PATH=${PATH}:/usr/local/go/bin" >> "$HOME"/.profile
echo "export PATH=${PATH}:/usr/local/go/bin" >> "$HOME"/.bashrc
source "$HOME"/.profile
go version
set +x

prompt_continue "Continue?" "$AUTO_YES"

### install goland
print_checklist_item "install Goland"
set -x
cd "${HOME}"
GOLAND_VER="2022.2.4"
sudo rm -rf /opt/GoLand*

curl -L --output ./goland-${GOLAND_VER}.tar.gz https://download.jetbrains.com/go/goland-${GOLAND_VER}.tar.gz
sudo tar xzf ./goland-${GOLAND_VER}.tar.gz -C /opt/
rm ./goland-${GOLAND_VER}.tar.gz

echo "alias goland=/opt/GoLand-${GOLAND_VER}/bin/goland.sh" >> "$HOME"/.profile
echo "alias goland=/opt/GoLand-${GOLAND_VER}/bin/goland.sh" >> "$HOME"/.bashrc
set +x

prompt_continue "Continue?" "$AUTO_YES"

### install rustup, rust and cargo
print_checklist_item "install Rust"
set -x

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "${HOME}/.profile"
rustup update
cargo --version
set +x

prompt_continue "Continue?" "$AUTO_YES"

### install clion
print_checklist_item "install CLion"
set -x
cd "${HOME}"
CLION_VER="2022.2.4"
sudo rm -rf /opt/clion*

curl -L --output ./clion-${CLION_VER}.tar.gz https://download.jetbrains.com/cpp/CLion-${CLION_VER}.tar.gz
sudo tar xzf ./clion-${CLION_VER}.tar.gz -C /opt/
rm -f ./clion-${CLION_VER}.tar.gz

echo "alias clion='/opt/clion-${CLION_VER}/bin/clion.sh'" >> "$HOME"/.profile
echo "alias clion='/opt/clion-${CLION_VER}/bin/clion.sh'" >> "$HOME"/.bashrc
set +x

prompt_continue "Continue?" "$AUTO_YES"

### install docker
print_checklist_item "install Docker"
set -x
sudo pacman -Sy --noconfirm docker
sudo pacman -Sy --noconfirm docker-compose
sudo systemctl enable docker
# allows non-root users to use docker
sudo usermod -a -G docker "$USER_NAME"
docker -v
set +x

prompt_continue "Continue?" "$AUTO_YES"



#######################################################################
######## COMMAND LINE #################################################
#######################################################################
print_header_section "Customizing .bashrc and .profile"


### customize prompt
print_checklist_item "customizing terminal prompt"
# shellcheck disable=SC2016
PROMPT='
function __my_prompt_command() {
    local EXIT_CODE="$?"

    local NORMAL_WHITE="\[\033[0;37m\]"
    local BOLD_WHITE="\[\033[1;97m\]"
    local BOLD_GREEN="\[\033[1;92m\]"
    local BOLD_RED="\[\033[1;91m\]"
    local RESET="\[\033[0m\]"

    PS1="${NORMAL_WHITE}[${BOLD_WHITE}\u@\h${NORMAL_WHITE}]-[${BOLD_GREEN}\w${NORMAL_WHITE}]-["
    if [ $EXIT_CODE != 0 ]; then
        # Add red if exit code non 0
        PS1+="${BOLD_RED}${EXIT_CODE}${NORMAL_WHITE}"
    else
        PS1+="${BOLD_GREEN}${EXIT_CODE}${NORMAL_WHITE}"
    fi
    PS1+="]${RESET} 🛠  "
}

PROMPT_COMMAND=__my_prompt_command
'

echo "$PROMPT" >> "${HOME}/.profile"
echo "$PROMPT" >> "${HOME}/.bashrc"

### add some aliases
print_checklist_item "setting aliases"
echo -x
ALIAS_LL="alias ll=\"ls -alh\""
echo "$ALIAS_LL" >> "${HOME}/.profile"
echo "$ALIAS_LL" >> "${HOME}/.bashrc"
ALIAS_K="alias k=\"kubectl\""
echo "$ALIAS_K" >> "${HOME}/.profile"
echo "$ALIAS_K" >> "${HOME}/.bashrc"
echo +x

source "$HOME"/.profile