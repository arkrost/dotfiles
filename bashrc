RED="\[$(tput setaf 167)\]"
GREEN="\[$(tput setaf 107)\]"
YELLOW="\[$(tput setaf 215)\]"
CYAN="\[$(tput setaf 103)\]"
RESET="\[$(tput sgr0)\]"
ARROW=`echo -e "\xe2\x9d\xaf"`
export PS1="${CYAN}\w ${RED}$ARROW${YELLOW}$ARROW${GREEN}$ARROW${RESET} "

alias c='clear'
