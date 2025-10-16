path=(~/.local/bin $path)
#node
path=(/opt/homebrew/opt/node@22/bin ~/.npm-packages/bin $path)
# haskell
path=(~/.cabal/bin ~/.ghcup/bin $path)
# rust
source "$HOME/.cargo/env"

mkdir -p ~/.zfunc
fpath+=~/.zfunc
rustup completions zsh cargo > ~/.zfunc/_cargo
rustup completions zsh rustup > ~/.zfunc/_rustup

export LC_ALL='en_US.UTF-8'
export EDITOR=nvim

# completion
autoload -Uz compinit && compinit -i

# prompt
PROMPT='%F{5}%n%f %~ %B%F{2}>%f%b '

# history
HISTFILE=~/.zhistory
HISTSIZE=1000                   # history lines within session
SAVEHIST=1000                   # history lines saved to file
setopt HIST_IGNORE_DUPS         # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS     # Delete old recorded entry if new entry is a duplicate.
setopt SHARE_HISTORY            # Share history between all sessions.
setopt HIST_VERIFY              # Don't execute immediately upon history expansion.
setopt HIST_IGNORE_SPACE        # Don't record an entry starting with a space.

# emacs keybindings
bindkey -e

# aliases
alias up='brew update && brew upgrade && brew upgrade --cask && brew cleanup'
alias rm=trash
alias c='clear'
alias gbc='git br --merged | rg -v "\* .*" | xargs git br -D'

alias l='eza -l'
alias ll='eza -TlL 2'
alias la='eza -la'
alias nv='nvim'

# tempo-io
export TESTCONTAINERS_RYUK_DISABLED=true
export CLOUD_HOME=~/ALM/cloud
export LOCAL_DOMAIN=arost-1.dev.structure.app
alias arost_1_env='$CLOUD_HOME/bootstrap/bfc.sh arost-1'

# nix
# NB: /nix/nix-installer uninstall
nix_path='/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
[ -f $nix_path ] && source $nix_path

# ocaml
if [ $commands[opam] ]; then
  source <(opam env)
fi

# fzf
# NB: /opt/homebrew/opt/fzf/install
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
FZF_THEME=(
  --cycle
  --layout=reverse
  --color fg:7,bg:-1,hl:4,fg+:11,bg+:0,hl+:4
  --color pointer:1,spinner:2,marker:3,prompt:4,info:5
)

FZF_PREVIEW=(
  "--preview 'bat --style=numbers --color=always --line-range :500 {}'"
)

export FZF_DEFAULT_OPTS="$FZF_THEME $FZF_PREVIEW"

# kubernetes
if [ $commands[kubectl] ]; then
  source <(kubectl completion zsh)
fi

# base commands
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(atuin init zsh --disable-up-arrow --disable-ctrl-r)" # just keep the history

# zinit setup
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# plugins
zinit light Aloxaf/fzf-tab
zinit light zuxfoucault/colored-man-pages_mod
zinit light zdharma/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
compinit -i # update completions
zstyle ':fzf-tab:*' fzf-flags $FZF_THEME

