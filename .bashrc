#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias ..='cd ..'



#PS1='[\u@\h \W]\$ '
PS1='\[\033[01;32m\]\u@\h \[\033[1;34m\]\w\[\033[0m\] \$ '

[[ "PS1" ]] && /usr/bin/fortune
