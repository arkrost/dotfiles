These are my personal configs. Exec

```
stow --no-folding --target "$HOME" .
```

to link the configs and exec

```
brew bundle install
```

to install the applications.

To unlink configs exec
```
stow --target "$HOME" -D .
```
