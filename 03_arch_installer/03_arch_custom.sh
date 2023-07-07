#!/bin/bash
set -e 

print_header "User space customization
(4/4)"

# load configs
source ./config.gen.sh
check_vars

#######################################################################
######## USERSPACE PROGRAMS ###########################################
#######################################################################

cd ~
sudo pacman -Syu

### install go
GO_VER=1.19.3
rm -rf /usr/local/go
curl -L --output ./go${GO_VER}.linux-amd64.tar.gz https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz
tar -C /usr/local -xzf ./go${GO_VER}.linux-amd64.tar.gz

echo "export PATH=${PATH}:/usr/local/go/bin" >> "$HOME"/.profile
source "$HOME"/.profile
go version

### install goland
GOLAND_VER="2022.2.4"
curl -L --output ./goland-${GOLAND_VER}.tar.gz https://download.jetbrains.com/go/goland-${GOLAND_VER}.tar.gz
tar xzf ./goland-${GOLAND_VER}.tar.gz -C /opt/

### install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh # rustup, rust and cargo
rustup update
cargo --version

echo "export PATH=${PATH}:~/.cargo/bin" >> "$HOME"/.profile
source "$HOME"/.profile
cargo --version

### install clion
CLION_VER="2022.2.4"
curl -L --output ./clion-${CLION_VER}.tar.gz https://download.jetbrains.com/cpp/CLion-${CLION_VER}.tar.gz
tar xzf ./clion-${CLION_VER}.tar.gz -C /opt/

### install docker
pacman -Sy docker
pacman -Sy docker-compose

systemctl start docker
systemctl enable docker

sudo docker info
sudo docker run hello-world

# allows non-root users to use docker
sudo usermod -a -G docker "$USER_NAME"



#######################################################################
######## COMMAND LINE #################################################
#######################################################################

### customize prompt
# shellcheck disable=SC2089
# shellcheck disable=SC2016
PROMPT='function __my_prompt_command() {
    local EXIT_CODE="$?"

    local NORMAL_WHITE="\[\e[0;37m\]"
    local BOLD_WHITE="\[\e[1;97m\]"
    local BOLD_GREEN="\[\e[1;92m\]"
    local BOLD_RED="\[\e[1;91m\]"
    local RESET="\[\e[0m\]"

    PS1="${NORMAL_WHITE}[${BOLD_WHITE}\u@\h${NORMAL_WHITE}]-[${BOLD_GREEN}\w${NORMAL_WHITE}]-["
    if [ $EXIT_CODE != 0 ]; then
        PS1+="${BOLD_RED}${EXIT_CODE}${NORMAL_WHITE}"        # Add red if exit code non 0
    else
        PS1+="${BOLD_GREEN}${EXIT_CODE}${NORMAL_WHITE}"
    fi
    PS1+="] 🛠️  ${RESET}"
}

PROMPT_COMMAND=__my_prompt_command'

echo "$PROMPT" >> ~/.profile
echo "$PROMPT" >> ~/.bash_profile

### add some aliases
ALIAS_LL="alias ll=\"ls -alh\""
echo "$ALIAS_LL" >> ~/.profile
echo "$ALIAS_LL" >> ~/.bash_profile

ALIAS_K="alias k=\"kubectl\""
echo "$ALIAS_K" >> ~/.profile
echo "$ALIAS_K" >> ~/.bash_profile

### reload
source ~/.bash_profile

