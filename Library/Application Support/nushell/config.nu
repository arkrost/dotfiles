$env.PATH = ($env.PATH | prepend [
  '~/.local/bin'
  '~/.cargo/bin'
  '~/.npm-packages/bin'
  '/opt/homebrew/opt/node@18/bin'
  '/opt/homebrew/bin'
])

$env.config = {
  show_banner: false,
}

# alias up='brew update && brew upgrade && brew upgrade --cask && brew cleanup'

alias l = eza -L 1 -Ta
alias la = eza -la
alias c = clear
alias rm = trash
alias nv = nvim

def gbc [] {
  git br --merged | rg -v '\*.*' | lines | str trim | each  { |b| git br -D $b } | str trim
}

$env.EDITOR = "hx"
$env.TESTCONTAINERS_RYUK_DISABLED = true

source ~/.cache/nu/starship.nu
source ~/.cache/nu/zoxide.nu
source ~/.cache/nu/atuin.nu
