autoload -Uz compinit && compinit -i

setopt COMPLETE_IN_WORD    # Complete from both ends of a word.
setopt ALWAYS_TO_END       # Move cursor to the end of a completed word.
setopt MENU_COMPLETE       # Autoselect the first completion entry. 

zstyle ':completion:*:*:*:*' menu select
zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'

zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:approximate:*' max-errors 3 numeric

PROMPT="%F{103}%~ %F{167}❯%F{215}❯%F{107}❯%f "

setopt auto_cd

alias c='clear'
