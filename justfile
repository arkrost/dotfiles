# Personal configs management

# Link configs to home directory
link:
	pkgx stow --no-folding --target "$HOME" .

# Install applications via brew
install:
	brew bundle install

# Unlink configs from home directory
unlink:
	pkgx stow --target "$HOME" -D .

# Show help
help:
	@just --list
