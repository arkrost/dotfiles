# zprezto
zstyle ':prezto:load' pmodule \
  'environment' \
  'history' \
  'directory' \
  'completion' \
  'fasd' \
  'git' \
  'history-substring-search' \
  'prompt'

zstyle ':prezto:module:prompt' theme 'local'

if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/runcoms/zshrc" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/runcoms/zshrc"
fi

# alias
alias c='clear'
unalias gb

export GOPATH=$HOME/Project/gocode
export GO15VENDOREXPERIMENT=1

typeset -U path
path=($GOPATH/bin $path[@])
