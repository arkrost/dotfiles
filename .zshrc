path=(~/.local/bin $path)
#node
path=(/opt/homebrew/opt/node@18/bin ~/.npm-packages/bin $path)
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
zstyle ':completion:*' menu select

# prompt
autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git*' formats '%F{2}%b%f'

precmd () {
  vcs_info
}

setopt PROMPT_SUBST
PROMPT='%F{5}%n%f %~ %B%F{2}>%f%b '
RPROMPT='${vcs_info_msg_0_}'

setopt AUTOCD

# history
HISTFILE=~/.zhistory
HISTSIZE=1000                   # history lines within session
SAVEHIST=1000                   # history lines saved to file
setopt HIST_IGNORE_DUPS         # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS     # Delete old recorded entry if new entry is a duplicate.
setopt SHARE_HISTORY            # Share history between all sessions.
setopt HIST_VERIFY              # Don't execute immediately upon history expansion.
setopt HIST_IGNORE_SPACE        # Don't record an entry starting with a space.

# keybindings
bindkey '^[[3~' delete-char

autoload -U up-line-or-beginning-search && zle -N up-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search

autoload -U down-line-or-beginning-search && zle -N down-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# aliases
alias up='brew update && brew upgrade && brew upgrade --cask && brew cleanup'
alias lock='chflags uchg'
alias unlock='chflags nouchg'
alias rm=trash
alias c='clear'
alias gbc='git br --merged | rg -v "\* .*" | xargs git br -D'

alias l='exa -l'
alias ll='exa -TlL 2'
alias la='exa -la'
alias nv='nvim'

# almrc
source "${ZDOTDIR:-$HOME}/.almrc"

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
export FZF_DEFAULT_OPTS='--cycle --layout=reverse'

# kubernetes
if [ $commands[kubectl] ]; then
  source <(kubectl completion zsh)
fi

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

### end of Zinit's installer
zinit light Aloxaf/fzf-tab
zinit light hlissner/zsh-autopair

# base commands
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(atuin init zsh --disable-up-arrow)"
