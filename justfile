# Personal configs management

# Link configs to home directory
link:
	stow --no-folding --target "$HOME" .

# Install applications via brew
install:
	brew bundle install

# Unlink configs from home directory
unlink:
	stow --target "$HOME" -D .

# Show help
help:
	@just --list
