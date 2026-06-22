# env.sh — shell-neutral environment + PATH.
#
# Sourced by BOTH shells so there is a single source of truth:
#   - ~/.denrc   (Den, the primary shell)
#   - ~/.zshrc   (zsh fallback)
# Keep this POSIX-sh compatible (no zsh/bash-only syntax) so Den and zsh agree.
# Aliases live in aliases.sh; prompt/plugins are configured in .config/den.jsonc.

# ---------------------------------------------------------------------------
# Core
# ---------------------------------------------------------------------------
export DOTFILES="$HOME/.dotfiles"

# Locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Claude Code
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=unlimited

# Default editor — Zed (installed via apps.yaml; CLI at ~/.local/bin/zed).
# `--wait` blocks until the buffer closes so `git commit`/rebase work correctly.
# git has no core.editor set, so it honours $EDITOR automatically.
export EDITOR="zed --wait"
export VISUAL="zed --wait"

# Bun
export BUN_INSTALL="$HOME/.bun"

# ---------------------------------------------------------------------------
# PATH
# Each `export PATH=NEW:$PATH` prepends, so the LAST line wins for ties.
# ---------------------------------------------------------------------------
# Pantry-managed binaries (bun, gh, eza, git, zig, ...) — replaces Homebrew.
# Zig (Den's 0.17-dev toolchain) is the .bin shim; see deps.yaml.
export PATH="$HOME/.local/share/pantry/global/bin:$PATH"
export PATH="$HOME/.local/share/pantry/global/pantry_modules/.bin:$PATH"

# Homebrew — kept only for GUI casks Pantry cannot manage; harmless if absent.
export PATH="/opt/homebrew/bin:$PATH"

# PHP 8.4
export PATH="/opt/homebrew/opt/php@8.4/bin:$PATH"

# Composer global tools
export PATH="$HOME/.composer/vendor/bin:$PATH"

# Windsurf
export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# Bun bin
export PATH="$BUN_INSTALL/bin:$PATH"

# Local scripts
export PATH="/usr/local/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Dotfiles bin (highest fixed priority)
export PATH="$DOTFILES/bin:$PATH"

# Project-local binaries before global ones
export PATH="node_modules/.bin:vendor/bin:$PATH"
export PATH=".:$PATH"
