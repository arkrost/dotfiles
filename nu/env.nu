$env.ENV_CONVERSIONS = {
  "PATH": {
    from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
    to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
  }
}

/opt/homebrew/bin/starship init nu | save -f "~/.cache/nu/starship.nu"
/opt/homebrew/bin/zoxide init nushell | save -f "~/.cache/nu/zoxide.nu"