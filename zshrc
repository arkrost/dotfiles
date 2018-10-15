path=(~/.local/bin $path)

alias c='clear'
alias gbc='git br | grep -v "*" | xargs git br -D'
alias l='tree -L 1 -Ca'
alias la='ls -la'

PROMPT='%F{2}λ%f '

autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git*' formats '%F{2}%b%f'

precmd () {
   vcs_info
   print -P "%F{4}%n%f %~ $vcs_info_msg_0_"
}

autoload -Uz compinit && compinit

setopt COMPLETE_IN_WORD    # Complete from both ends of a word.
setopt ALWAYS_TO_END       # Move cursor to the end of a completed word.
setopt MENU_COMPLETE       # Autoselect the first completion entry. 

zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' group-order aliases local-directories

zstyle ':completion:*:descriptions' format ' %F{3}-- %d --%f'
zstyle ':completion:*:corrections' format ' %F{2}-- %d (errors: %e) --%f'
zstyle ':completion:*:warnings' format ' %F{1}-- no matches found --%f'

# Complete . and .. special directories
zstyle ':completion:*' special-dirs true

# case insensitive (all), partial-word and substring completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'

# Ignore internal zsh functions
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:aliases' ignored-patterns '_*'

zstyle ':completion:*' completer _complete _prefix _approximate
zstyle ':completion:*:prefix:*' add-space true
zstyle ':completion:*:approximate:*' max-errors 2 numeric

# Cache expensive completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zsh

setopt AUTO_CD

HISTFILE=~/.zhistory
HISTSIZE=1000                   # history lines within session
SAVEHIST=1000                   # history lines saved to file
setopt HIST_IGNORE_DUPS         # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS     # Delete old recorded entry if new entry is a duplicate.
setopt SHARE_HISTORY            # Share history between all sessions.
setopt HIST_VERIFY              # Don't execute immediately upon history expansion.
setopt HIST_IGNORE_SPACE        # Don't record an entry starting with a space.

bindkey '^[[3~' delete-char
bindkey '^F' forward-word
bindkey '^B' backward-word

autoload -U up-line-or-beginning-search && zle -N up-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search

autoload -U down-line-or-beginning-search && zle -N down-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

for f (~/.zshrc.d/*(.N)) . $f