export PS1="$(tput setaf 4)\u $(tput sgr0)\w $(tput setaf 2)$ $(tput sgr0)"

# mac specific
export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
alias up='brew update && brew upgrade && brew cleanup'

alias c='clear'
alias e='nano -w'
alias gbc='git br | grep -v "*" | xargs git br -D'