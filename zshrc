if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/runcoms/zshrc" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/runcoms/zshrc"
fi

# export
export RUST_SRC_PATH="$HOME/.rust/rust/src"

# alias
alias c='clear'
alias v='nvim'
