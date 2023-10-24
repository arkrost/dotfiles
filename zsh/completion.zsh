autoload -Uz compinit && compinit -i

setopt COMPLETE_IN_WORD    # Complete from both ends of a word.
setopt ALWAYS_TO_END       # Move cursor to the end of a completed word.
setopt MENU_COMPLETE       # Autoselect the first completion entry.

zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' group-order aliases functions local-directories

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

zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'

# Cache expensive completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zsh
