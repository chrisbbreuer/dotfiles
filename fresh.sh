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
#    The installer drops the `pantry` binary in ~/.local/bin (its default
#    PANTRY_INSTALL_DIR); `pantry install` then populates the global tool dirs.
if ! command -v pantry >/dev/null 2>&1; then
  echo "==> Installing Pantry..."
  curl -fsSL https://pantry.dev | bash
fi
export PATH="$HOME/.local/bin:$HOME/.local/share/pantry/global/bin:$HOME/.local/share/pantry/global/pantry_modules/.bin:$PATH"

# 3. ALL global dependencies via Pantry — bun, git, gh, eza, coreutils, grep,
#    bash, and Zig (Den's build toolchain) from deps.yaml, plus the GUI apps and
#    fonts from apps.yaml / fonts.yaml (Pantry reads those siblings automatically).
#    Pantry installs everything NATIVELY — no Homebrew, no mas, no extra tooling.
#
#    IMPORTANT: a *bare* `pantry install` treats this repo as a project and drops
#    the CLI tools into a local, gitignored `./pantry/` dir that is NOT on PATH —
#    so git/gh/zig/bun would never be found and every later step would fail. The
#    `--user` flag honours `global: true` in deps.yaml and installs them into the
#    canonical user dir (~/.local/share/pantry/global/bin) that env.sh adds to
#    PATH. That's the install that matters, so run it first.
echo "==> Installing CLI tools via Pantry (user-global, onto PATH)..."
( cd "$DOTFILES" && pantry install --user ) \
  || echo "    WARNING: 'pantry install --user' reported errors. Most tools should still be installed — continuing."

# GUI apps + fonts (apps.yaml / fonts.yaml). Newer Pantry installs these during
# the --user run above; older releases only wire them up through the project
# path, so run a bare install too. Any CLI shims it writes go to the gitignored
# ./pantry and are harmless — the user-global copies above are what's on PATH.
# Mac App Store apps open in the App Store for a one-click install; already
# installed apps/fonts are skipped, so this is safe to re-run.
echo "==> Installing GUI apps & fonts via Pantry..."
( cd "$DOTFILES" && pantry install ) \
  || echo "    (some apps/fonts could not be installed — review the output above)"

# Sanity check: Den needs Zig 0.17-dev. If Pantry's registry hasn't yet published
# a recent enough dev build, surface it clearly rather than failing cryptically.
if ! zig version 2>/dev/null | grep -q '^0\.17'; then
  echo "WARNING: 'zig' is not 0.17.x after 'pantry install'." >&2
  echo "         Bump the ziglang.org pin in deps.yaml to an available dev build" >&2
  echo "         (see https://ziglang.org/download), then re-run 'pantry install'." >&2
fi

# 4. Build & install Den (the shell). Clone over SSH (git@) — Den is private, so
#    HTTPS would prompt for a password and fail (GitHub dropped password auth).
#    ssh.sh has already put your key on GitHub, so SSH just works. Den's build is
#    non-fatal: if Zig isn't new enough yet, keep going so the secrets/.env/SSH
#    recovery below still runs — you can rebuild Den later with `bun run den`.
if [ ! -d "$CODE/den" ]; then
  echo "==> Cloning Den (SSH)..."
  git clone git@github.com:stacksjs/den.git "$CODE/den" \
    || echo "    ! could not clone Den — check 'ssh -T git@github.com'. Skipping Den build."
fi
if [ -d "$CODE/den" ]; then
  echo "==> Building Den..."
  if ( cd "$CODE/den" && zig build -Doptimize=ReleaseFast ); then
    ln -sf "$CODE/den/zig-out/bin/den" "$HOME/.local/bin/den"
  else
    echo "    ! Den build failed (often a Zig version mismatch). Continuing." >&2
    echo "      Fix the ziglang.org pin in deps.yaml, then: cd ~/Code/den && zig build -Doptimize=ReleaseFast" >&2
  fi
fi

# 5. Symlink shell configs.
ln -sf "$DOTFILES/.denrc" "$HOME/.denrc"                          # Den shell startup
ln -sf "$DOTFILES/.config/den.jsonc" "$HOME/.config/den.jsonc"    # Den declarative config
rm -f "$HOME/.zshrc"; ln -sf "$DOTFILES/.zshrc" "$HOME/.zshrc"    # zsh fallback

# 6. Recover EVERYTHING from iCloud in one shot: credentials, .env files and app
#    settings, then every repo cloned back to its original ~/Code path with all
#    local-only git work (unpushed commits, stashes, uncommitted, untracked),
#    then any remaining org repos, then your mail accounts (opens the generated
#    profile + Internet Accounts to finish). See bin/dot-recover. Requires iCloud
#    Drive to be signed in and synced; if it isn't here yet we skip with instructions.
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
  - GUI apps & fonts come from apps.yaml / fonts.yaml (installed natively by
    'pantry install' above; Mac App Store apps open in the App Store to install).
  - Mail: recovery set up your accounts. Approve the staged profile (System
    Settings → General → Device Management) and sign into Gmail/iCloud in the
    Internet Accounts window it opened. (Re-run anytime: `bun run mail`.)
  - If recovery was skipped (iCloud not synced) or gh wasn't authed, finish with:
        gh auth login          # if cloning needs it
        cd ~/.dotfiles && bun run recover   # also sets up mail
  - Keep your off-machine copy fresh before the NEXT wipe with:
        cd ~/.dotfiles && bun run prewipe      # = backup (secrets) + rescue (git work)
  - To make Den your login shell, see the opt-in note at the bottom of .zshrc,
    or run:  echo "$HOME/.local/bin/den" | sudo tee -a /etc/shells && chsh -s "$HOME/.local/bin/den"
EOF
