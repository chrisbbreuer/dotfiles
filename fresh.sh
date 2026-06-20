#!/bin/sh
# fresh.sh — set up a brand-new Mac from these dotfiles.
#
# Modern stack (no Homebrew / oh-my-zsh / starship / mackup):
#   - Pantry   -> all CLI tooling incl. Zig    (replaces Homebrew Brewfile)
#   - Den      -> the shell + native prompt/plugins (replaces zsh/oh-my-zsh/starship)
#   - ts-backups -> app-settings backup/restore  (replaces Mackup)
#
# Idempotent: safe to re-run.
set -e

echo "Setting up your Mac..."

DOTFILES="$HOME/.dotfiles"
CODE="$HOME/Code"
mkdir -p "$CODE" "$HOME/.local/bin" "$HOME/.config"

# 1. Xcode Command Line Tools — provides git for the first clone.
if ! xcode-select -p >/dev/null 2>&1; then
  echo "==> Installing Xcode Command Line Tools..."
  xcode-select --install || true
  echo "    Re-run ./fresh.sh once the CLT install finishes."
fi

# 2. Pantry — replaces Homebrew for every command-line tool.
if ! command -v pantry >/dev/null 2>&1; then
  echo "==> Installing Pantry..."
  curl -fsSL https://pantry.sh | sh
fi
export PATH="$HOME/.local/share/pantry/global/bin:$HOME/.local/share/pantry/global/pantry_modules/.bin:$PATH"

# 3. ALL global dependencies (see deps.yaml) via Pantry — bun, git, gh, eza,
#    coreutils, grep, bash, and Zig (Den's build toolchain).
echo "==> Installing all dependencies via Pantry..."
( cd "$DOTFILES" && pantry install )

# Sanity check: Den needs Zig 0.17-dev. If Pantry's registry hasn't yet published
# a recent enough dev build, surface it clearly rather than failing cryptically.
if ! zig version 2>/dev/null | grep -q '^0\.17'; then
  echo "WARNING: 'zig' is not 0.17.x after 'pantry install'." >&2
  echo "         Bump the ziglang.org pin in deps.yaml to an available dev build" >&2
  echo "         (see https://ziglang.org/download), then re-run 'pantry install'." >&2
fi

# 4. Build & install Den (the shell).
if [ ! -d "$CODE/den" ]; then
  echo "==> Cloning Den..."
  git clone https://github.com/stacksjs/den.git "$CODE/den"
fi
echo "==> Building Den..."
( cd "$CODE/den" && zig build -Doptimize=ReleaseFast )
ln -sf "$CODE/den/zig-out/bin/den" "$HOME/.local/bin/den"

# 5. Symlink shell configs.
ln -sf "$DOTFILES/.denrc" "$HOME/.denrc"                          # Den shell startup
ln -sf "$DOTFILES/.config/den.jsonc" "$HOME/.config/den.jsonc"    # Den declarative config
rm -f "$HOME/.zshrc"; ln -sf "$DOTFILES/.zshrc" "$HOME/.zshrc"    # zsh fallback

# 6. Recover EVERYTHING from iCloud in one shot: credentials, .env files and app
#    settings, then every repo cloned back to its original ~/Code path with all
#    local-only git work (unpushed commits, stashes, uncommitted, untracked),
#    then any remaining org repos. See bin/dot-recover. Requires iCloud Drive to
#    be signed in and synced; if it isn't here yet we skip with instructions.
ICLOUD_BK="$HOME/Library/Mobile Documents/com~apple~CloudDocs/ts-backups"
if [ -d "$ICLOUD_BK" ]; then
  "$DOTFILES/bin/dot-recover" || echo "    (recover reported problems — review output above)"
else
  echo "==> No iCloud backup found yet. Sign in to iCloud, let it finish syncing,"
  echo "    then run:  cd ~/.dotfiles && bun run recover"
fi

# 7. macOS defaults — reloads the shell, so run this last.
echo "==> Applying macOS defaults..."
. "$DOTFILES/.macos"

cat <<'EOF'

All done! Next steps:
  - Open a new terminal and run `den` (or point your terminal app at ~/.local/bin/den).
  - Install GUI apps & fonts from apps.md (Pantry does not manage .app bundles).
  - If recovery was skipped (iCloud not synced) or gh wasn't authed, finish with:
        gh auth login          # if cloning needs it
        cd ~/.dotfiles && bun run recover
  - Keep your off-machine copy fresh before the NEXT wipe with:
        cd ~/.dotfiles && bun run prewipe      # = backup (secrets) + rescue (git work)
  - To make Den your login shell, see the opt-in note at the bottom of .zshrc,
    or run:  echo "$HOME/.local/bin/den" | sudo tee -a /etc/shells && chsh -s "$HOME/.local/bin/den"
EOF
