if [ $(tput colors) -gt 8 ]; then
    RED="$(tput setaf 167)"
    GREEN="$(tput setaf 107)"
    YELLOW="$(tput setaf 215)"
    CYAN="$(tput setaf 103)"
    RESET="$(tput sgr0)"
    export PS1="${CYAN}\w ${RED}❯${YELLOW}❯${GREEN}❯${RESET} "
fi

alias c='clear'
