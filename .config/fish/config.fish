# homebrew
eval (/opt/homebrew/bin/brew shellenv)

# my paths
fish_add_path -gm /opt/homebrew/opt/node@24/bin ~/.npm-packages/bin
fish_add_path -gm ~/.bun/bin
fish_add_path -gm ~/.cabal/bin ~/.ghcup/bin
fish_add_path -gm ~/.cargo/bin
fish_add_path -gm ~/.local/bin

# Interactive config
status is-interactive || exit

function fish_user_key_bindings
    fish_default_key_bindings -M insert
    fish_vi_key_bindings --no-erase insert
end

set -g fish_greeting
set -x fish_color_valid_path green -i
set -x fish_pager_color_prefix yellow --bold
set -x fish_pager_color_progress magenta
set -x fish_color_autosuggestion brblack
set -x fish_color_param
set -x fish_color_command

set -x EDITOR hx
set -x SHELL (which fish)
set -x FZF_DEFAULT_OPTS "--cycle --layout=reverse --no-bold
    --preview 'bat --style=numbers --color=always --line-range :500 {}'
    --color fg:7,bg:-1,hl:4,fg+:11,bg+:0,hl+:4
    --color pointer:1,spinner:2,marker:3,prompt:4,info:5"
set -x BAT_THEME base16

abbr -a gbc 'git br --merged | rg -v "\\* .*" | xargs git br -D'
abbr -a up 'brew update && brew upgrade -y && brew cleanup'
abbr -a dump 'brew bundle dump --no-describe --force'

alias rm='trash'
abbr -a c clear
abbr -a .. 'cd ..'

abbr -a e hx
abbr -a nv nvim
abbr -a g lazygit
abbr -a d lazydocker

abbr -a l eza -l
abbr -a ll eza -TlL 2
abbr -a la eza -la

# integrations
starship init fish | source
zoxide init fish | source
atuin init fish --disable-up-arrow | source

# ALM
set -gx JAVA_HOME (/usr/libexec/java_home -v 25)
set -gx MAVEN_OPTS '-Djdk.tls.client.protocols=TLSv1.2'
set -gx COMPOSE_ANSI always
set -gx DOCKER_HOST "unix:///Users/$USER/.colima/docker.sock"

set -gx TESTCONTAINERS_RYUK_DISABLED true

set -gx CDN_URL
set -gx BASE_URL_US arost-1.dev.structure.app
set -gx BASE_URL_EU arost-1.dev.structure.app

set -gx CLOUD_HOME "$HOME/Projects/cloud/master/"
set -gx LOCAL_DOMAIN "arost-1.dev.structure.app"
alias rebuild_cloud='$CLOUD_HOME/bootstrap/rebuild.sh'

function arost_env
    set name $argv[1]
    set -gx LOCAL_DOMAIN "arost-$name.dev.structure.app"
    "$CLOUD_HOME/bootstrap/bfc.sh" "arost-$name"
end
