if [ $(tput colors) -gt 8 ]; then
    RED="\[$(tput setaf 167)\]"
    GREEN="\[$(tput setaf 107)\]"
    YELLOW="\[$(tput setaf 215)\]"
    CYAN="\[$(tput setaf 103)\]"
    RESET="\[$(tput sgr0)\]"
    export PS1="${CYAN}\w ${RED}❯${YELLOW}❯${GREEN}❯${RESET} "
fi

export PATH=/Library/TeX/texbin:/usr/local/bin:$PATH
export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)

alias up='brew update && brew upgrade && brew cleanup'

alias c='clear'
alias e='emacsclient'
