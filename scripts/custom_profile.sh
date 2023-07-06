
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

echo $PROMPT >> ~/.profile
echo $PROMPT >> ~/.bash_profile

ALIAS="alias ll=\"ls -alh\""
echo $ALIAS >> ~/.profile
echo $ALIAS >> ~/.bash_profile



source ~/.bash_profile
