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

zstyle ':prezto:module:prompt' theme 'sorin'

if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/runcoms/zshrc" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/runcoms/zshrc"
fi

# alias
alias c='clear'
alias v='nvim'

# path
export LOCAL_BIN=/home/ark/.local/bin
typeset -U path
path=($path[@])
