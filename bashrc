RED="\[$(tput setaf 1)\]"
GREEN="\[$(tput setaf 2)\]"
YELLOW="\[$(tput setaf 3)\]"
CYAN="\[$(tput setaf 4)\]"
RESET="\[$(tput sgr0)\]"
ARROW=`echo -e "\xe2\x9d\xaf"`
export PS1="${CYAN}\w ${RED}$ARROW${YELLOW}$ARROW${GREEN}$ARROW${RESET} "

alias c='clear'
