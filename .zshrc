# keymapping
bindkey '\e[3~' delete-char # del
bindkey '\e[2~' overwrite-mode #insert
bindkey '\e[H' beginning-of-line # Home
bindkey '\e[F' end-of-line # End
bindkey '\e[D' backward-char # Left arrow
bindkey '\e[C' forward-char # Right arrow
bindkey '\e[A' up-line-or-history # Up arrow
bindkey '\e[B' down-line-or-history # Down arrow
bindkey '\e[5~' history-beginning-search-backward # PageUp
bindkey '\e[6~' history-beginning-search-forward # PageDown
bindkey ';5D' backward-word # ctrl+left 
bindkey ';5C' forward-word #ctrl+right

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
PROMPT='%{$fg[magenta]%}%n%{$reset_color%} at %{$fg[yellow]%}%m%{$reset_color%} in %{$fg[green]%}%~%{$reset_color%} ☿ '
RPROMPT='[%*]'

# aliases
alias ls='ls --color=auto'
alias grep='grep --colour=auto'
