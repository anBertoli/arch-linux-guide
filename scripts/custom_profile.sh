
PROMPT="export PS1=\"\e[0;37m[\e[1;97m\u@\h\e[0;37m]-[\e[1;32m\w\e[0;37m]\e[1;97m ⚙️ \""
echo $PROMPT >> ~/.profile
echo $PROMPT >> ~/.bash_profile

ALIAS="alias ll=\"ls -alh\""
echo $ALIAS >> ~/.profile
echo $ALIAS >> ~/.bash_profile

source ~/.bash_profile
