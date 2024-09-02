# homebrew
eval (/opt/homebrew/bin/brew shellenv)

# my paths
fish_add_path -gm /opt/homebrew/opt/node@18/bin ~/.npm-packages/bin
fish_add_path -gm ~/.cargo/bin
fish_add_path -gm ~/.local/bin

# Interactive config
status is-interactive || exit

set -g fish_greeting
set -x fish_color_valid_path 'green' '-i'
set -x fish_pager_color_prefix 'yellow'  '--bold'
set -x fish_pager_color_progress 'magenta'
set -x fish_color_param
set -x fish_color_command

set -g fifc_editor 'nvim'
set -U fifc_keybinding \cx

set -x EDITOR nvim
set -x SHELL (which fish)
set -x FZF_DEFAULT_OPTS '--cycle --layout=reverse'

alias gbc='git br | grep -v "*" | xargs git br -D'
alias up='brew update && brew upgrade && brew cleanup'

alias rm='trash'
alias l='eza -l'
alias la='eza -la'
alias ll='eza -TlL 2'
alias c='clear'
alias nv='nvim'

# integrations
starship init fish | source
zoxide init fish | source
atuin init fish --disable-up-arrow | source

# ALM
set -gx JAVA_HOME (/usr/libexec/java_home -v 17)
set -gx MAVEN_OPTS '-Djdk.tls.client.protocols=TLSv1.2'

set -gx DOCKER_HOST "unix://$HOME/.colima/default/docker.sock"
set -gx TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE "$HOME/docker.sock"
set -gx TESTCONTAINERS_RYUK_DISABLED true

set -gx CLOUD_HOME "$HOME/ALM/cloud"
alias rebuild_cloud='$CLOUD_HOME/bootstrap/rebuild.sh'

alias arost_1_env='$CLOUD_HOME/bootstrap/bfc.sh arost-1'

function logs -d 'Pretty-print logs from personal cluster'
  stern -o raw "$argv[1]" | jq -rR '. as $raw | try (fromjson | (."@timestamp" | split("T") | last) +" \u001b[32m"+ .level +"\u001b[0m "+ (.thread_name) + " \u001b[33m" + (.attributeSpec) +"\u001b[0m [\u001b[34m"+ (.logger_name | split(".") | last) +"\u001b[0m] - "+.message + .stack_trace) catch ("\u001b[31m" + $raw + "\u001b[0m")'
end

set -gx CORE_MODULES 'backoffice,metadata,front,content,jira-integration,structure-integration,jira-egress,gantt-integration,item-attribute-store,item-attribute-subscription-hub,connect-lifecycle,tempo-integration,api-auth,post-deploy-manager,attribute-spec-compressor'
