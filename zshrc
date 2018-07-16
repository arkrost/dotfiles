autoload -Uz compinit && compinit -i

setopt COMPLETE_IN_WORD    # Complete from both ends of a word.
setopt ALWAYS_TO_END       # Move cursor to the end of a completed word.
setopt MENU_COMPLETE       # Autoselect the first completion entry. 

zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' group-order aliases local-directories
zstyle ':completion:*:descriptions' format ' %F{3}-- %d --%f'
zstyle ':completion:*:corrections' format ' %F{2}-- %d (errors: %e) --%f'
zstyle ':completion:*:warnings' format ' %F{1}-- no matches found --%f'

zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:approximate:*' max-errors 2 numeric

setopt auto_cd

PROMPT="%F{4}%n %f%~ %F{2}$%f "

path=(~/.local/bin $path)

alias c='clear'
alias gbc='git br | grep -v "*" | xargs git br -D'
alias l='tree -L 1 -Ca'
alias la='tree -Ca'

bindkey '^[[3~' delete-char
bindkey '^F' forward-word
bindkey '^B' backward-word

autoload -U up-line-or-beginning-search && zle -N up-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search

autoload -U down-line-or-beginning-search && zle -N down-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

for f (~/.zshrc.d/*(.N)) . $f
