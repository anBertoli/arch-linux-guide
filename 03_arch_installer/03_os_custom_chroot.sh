#!/bin/bash
set -e 

source ./config.sh
source ./print.sh

# load configs
check_conf_file
source ./config.gen.sh
check_vars



#######################################################################
######## GET NEW USER HOME ############################################
#######################################################################
print_header_section "Getting user home"
set -x
USER_HOME="$(getent passwd "${USER_NAME}" | cut -d: -f6)"
if [ -z "$USER_HOME" ]
then
      echo "USER_HOME is empty"
      exit 1
fi
set +x

print_text "Root HOME is '${HOME}'."
print_text "User HOME is '${USER_HOME}'."
prompt_continue "Continue?"



#######################################################################
######## USERSPACE PROGRAMS ###########################################
#######################################################################
#print_header_section "Programming languages and IDEs "
#
#set -x
#cd ~
#pacman --noconfirm -Syu
#set +x
#
#### install go
#print_checklist_item "install Go"
#set -x
#GO_VER=1.20
#rm -rf /usr/local/go
#
#curl -L --output ./go${GO_VER}.linux-amd64.tar.gz https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz
#tar -C /usr/local -xzf ./go${GO_VER}.linux-amd64.tar.gz
#rm ./go${GO_VER}.linux-amd64.tar.gz
#
#set +x
#print_text "Writing
#'export PATH=${PATH}:/usr/local/go/bin'
#to '${HOME}/.profile' and '${USER_HOME}/.profile'"
#set -x
#echo "export PATH=${PATH}:/usr/local/go/bin" >> "$HOME"/.profile
#echo "export PATH=${PATH}:/usr/local/go/bin" >> "$USER_HOME"/.profile
#source "$HOME"/.profile
#go version
#set +x
#
#prompt_continue "Continue?"
#
#### install goland
#print_checklist_item "install Goland"
#set -x
#GOLAND_VER="2022.2.4"
#rm -rf /opt/GoLand*
#
#curl -L --output ./goland-${GOLAND_VER}.tar.gz https://download.jetbrains.com/go/goland-${GOLAND_VER}.tar.gz
#tar xzf ./goland-${GOLAND_VER}.tar.gz -C /opt/
#rm ./goland-${GOLAND_VER}.tar.gz
#set +x
#
## TODO: CHECK
#print_text "Writing
#'export PATH=${PATH}:/opt/GoLand-${GOLAND_VER}/go/bin/goland.sh'
#to '${HOME}/.profile' and '${USER_HOME}/.profile'"
#set -x
#echo "export PATH=${PATH}:/opt/GoLand-${GOLAND_VER}/go/bin/goland.sh" >> "$HOME"/.profile
#echo "export PATH=${PATH}:/opt/GoLand-${GOLAND_VER}/go/bin/goland.sh" >> "$USER_HOME"/.profile
#set +x
#
#prompt_continue "Continue?"

chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.profile


### install rustup, rust and cargo
print_checklist_item "install Rust"
set -x
sudo -u "${USER_NAME}" /bin/bash -c "
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
rustup update
cargo --version
"
#sudo -u "${USER_NAME}" curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh # rustup, rust and cargo
#rustup update
cargo --version
set +x

print_text "Writing
'export PATH=${PATH}:~/.cargo/bin'
to '${HOME}/.profile' and '${USER_HOME}/.profile'"
set -x
echo "export PATH=${PATH}:~/.cargo/bin" >> "$HOME"/.profile
echo "export PATH=${PATH}:~/.cargo/bin" >> "$USER_HOME"/.profile
source "$HOME"/.profile
cargo --version
set +x

prompt_continue "Continue?"

### install clion
print_checklist_item "install CLion"
set -x
CLION_VER="2022.2.4"
rm -rf /opt/clion*

curl -L --output ./clion-${CLION_VER}.tar.gz https://download.jetbrains.com/cpp/CLion-${CLION_VER}.tar.gz
tar xzf ./clion-${CLION_VER}.tar.gz -C /opt/
rm ./clion-${GOLAND_VER}.tar.gz
set +x

print_text "Writing
export PATH=${PATH}:/opt/clion-${CLION_VER}/bin/clion.sh'
to '${HOME}/.profile' and '${USER_HOME}/.profile'"
set -x
echo "export PATH=${PATH}:/opt/clion-${CLION_VER}/bin/clion.sh" >> "$HOME"/.profile
echo "export PATH=${PATH}:/opt/clion-${CLION_VER}/bin/clion.sh" >> "$USER_HOME"/.profile
set +x

prompt_continue "Continue?"

### install docker
print_checklist_item "install Docker"
set -x
pacman -Sy --noconfirm docker
pacman -Sy --noconfirm docker-compose
systemctl enable docker
docker info
docker run hello-world

# allows non-root users to use docker
usermod -a -G docker "$USER_NAME"
set +x

prompt_continue "Continue?"

#######################################################################
######## COMMAND LINE #################################################
#######################################################################

### customize prompt
# shellcheck disable=SC2089
# shellcheck disable=SC2016
PROMPT='function __my_prompt_command() {
    local EXIT_CODE="$?"

    local NORMAL_WHITE="\033[0;37m"
    local BOLD_WHITE="\033[1;97m"
    local BOLD_GREEN="\033[1;92m"
    local BOLD_RED="\033[1;91m"
    local RESET="\033[0m"

    PS1="${NORMAL_WHITE}[${BOLD_WHITE}\u@\h${NORMAL_WHITE}]-[${BOLD_GREEN}\w${NORMAL_WHITE}]-["
    if [ $EXIT_CODE != 0 ]; then
        # Add red if exit code non 0
        PS1+="${BOLD_RED}${EXIT_CODE}${NORMAL_WHITE}"
    else
        PS1+="${BOLD_GREEN}${EXIT_CODE}${NORMAL_WHITE}"
    fi
    PS1+="] 🛠️  ${RESET}"
}

PROMPT_COMMAND=__my_prompt_command'

echo -x
echo "$PROMPT" >> "${USER_HOME}"/.profile
#echo "$PROMPT" >> ~/.bash_profile

### add some aliases
ALIAS_LL="alias ll=\"ls -alh\""
echo "$ALIAS_LL" >> "${USER_HOME}"/.profile
#echo "$ALIAS_LL" >> ~/.bash_profile

ALIAS_K="alias k=\"kubectl\""
echo "$ALIAS_K" >> "${USER_HOME}"/.profile
#echo "$ALIAS_K" >> ~/.bash_profile

#source "$HOME"/.profile
echo +x

### end
print_header_section "Checkpoint"
print_text "
${BOLD_INTENSE_GREEN}Success!${BOLD_INTENSE_WHITE}

All done, just reboot the system and use it.

Exiting.
"

