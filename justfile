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

# Import Rex settings
rex-import:
	defaults import com.superlogical.rex "{{justfile_directory()}}/rex-settings.plist"

# Export Rex settings
rex-export:
	defaults export com.superlogical.rex "{{justfile_directory()}}/rex-settings.plist"

# Show help
help:
	@just --list
