# completion settings
autoload -U compinit && compinit
setopt completealiases
zstyle ':completion:*' menu select

# history
SAVEHIST=100
HISTFILE=~/.histfile

# prompt settings
autoload -U colors && colors
setopt PROMPT_SUBST
PROMPT='%(#.%{$fg[red]%}%n%{$reset_color%}.%{$fg[magenta]%}%n%{$reset_color%} at %{$fg[yellow]%}%m%{$reset_color%}) in %{$fg[green]%}%~%{$reset_color%} # '
RPROMPT='[%*]'

# aliases
alias grep='grep --colour=auto'
alias ..='cd ..'
alias c='clear'
