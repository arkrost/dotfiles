$env.PATH = ($env.PATH | prepend [
  '~/.local/bin'
  '~/.cargo/bin'
  '~/.npm-packages/bin'
  '/opt/homebrew/opt/node@18/bin'
  '/opt/homebrew/bin'
])

$env.config = {
  show_banner: false,
  keybindings: [
    {
      name: fuzzy_history
      modifier: control
      keycode: char_r
      mode: [emacs, vi_normal, vi_insert]
      event: [
        {
          send: ExecuteHostCommand
          cmd: "commandline (
            history
              | each { |it| $it.command }
              | uniq
              | reverse
              | str join (char -i 0)
              | fzf --read0 --layout=reverse --height=40% -q (commandline)
              | decode utf-8
              | str trim
          )"
        }
      ]
    }
  ]
}

# alias up='brew update && brew upgrade && brew upgrade --cask && brew cleanup'

alias l = exa -L 1 -Ta
alias la = exa -la
alias c = clear
alias rm = trash

def gbc [] {
  git br --merged | rg -v '\*.*' | lines | str trim | each  { |b| git br -D $b } | str trim
}

$env.EDITOR = "hx"
$env.TESTCONTAINERS_RYUK_DISABLED = true

source ~/.cache/nu/starship.nu
source ~/.cache/nu/zoxide.nu
# source ~/.cache/nu/atuin.nu
