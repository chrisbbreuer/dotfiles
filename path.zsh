# Load dotfiles binaries
export PATH="$DOTFILES/bin:$PATH"

# Load Composer tools
export PATH="$HOME/.composer/vendor/bin:$PATH"

# Load Homebrew tools
export PATH="/opt/homebrew/bin:$PATH"

# Use project specific binaries before global ones
export PATH="node_modules/.bin:vendor/bin:$PATH"

# Use local scripts before global ones (e.g. when buddy is installed via brew)
export PATH=".:$PATH"
