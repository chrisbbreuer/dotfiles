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
# Mac App Store apps (apps.yaml `mas:` entries) install natively & SILENTLY via
# Pantry/CommerceKit — no `mas`, no App Store window popping up. The only part
# that needs root is the final `/usr/sbin/installer` step, so prime sudo now and
# keep the timestamp warm through the long install runs below. If you decline (or
# aren't an admin) Pantry just falls back to opening the App Store for those apps.
echo "==> Priming sudo for silent Mac App Store installs..."
if sudo -v 2>/dev/null; then
  ( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done ) &
  _SUDO_KEEPALIVE=$!
  trap 'kill "$_SUDO_KEEPALIVE" 2>/dev/null || true' EXIT
else
  echo "    (no sudo — Mac App Store apps will open in the App Store instead of installing silently)"
fi

echo "==> Installing CLI tools via Pantry (user-global, onto PATH)..."
( cd "$DOTFILES" && pantry install --user ) \
  || echo "    WARNING: 'pantry install --user' reported errors. Most tools should still be installed — continuing."

# GUI apps + fonts (apps.yaml / fonts.yaml). Newer Pantry installs these during
# the --user run above; older releases only wire them up through the project
# path, so run a bare install too. Any CLI shims it writes go to the gitignored
# ./pantry and are harmless — the user-global copies above are what's on PATH.
# Mac App Store apps install natively & silently (CommerceKit — no `mas`, no
# window) thanks to the primed sudo above; already installed apps/fonts are
# skipped, so this is safe to re-run.
echo "==> Installing GUI apps & fonts via Pantry..."
( cd "$DOTFILES" && pantry install ) \
  || echo "    (some apps/fonts could not be installed — review the output above)"

# Zed ships its CLI *inside* the app bundle, but Pantry's native app install only
# places Zed.app in /Applications — it does not put a `zed` on PATH. Symlink it
# ourselves so EDITOR="zed --wait" (env.sh) resolves. Idempotent; no-op if absent.
if [ -x "/Applications/Zed.app/Contents/MacOS/cli" ]; then
  ln -sf "/Applications/Zed.app/Contents/MacOS/cli" "$HOME/.local/bin/zed"
  echo "    ✓ zed -> $HOME/.local/bin/zed"
fi

# gh lives in Pantry's global bin, which is only on PATH once env.sh is sourced
# (interactive shells). But git's github.com credential helper is `!gh auth
# git-credential` — git runs it in a bare subprocess that does NOT source env.sh,
# so `gh` is off PATH there and every HTTPS push/pull fails to authenticate.
# Symlink gh into ~/.local/bin (always on PATH, like zed/den/claude) so the
# credential helper resolves it in any context. Idempotent; no-op if gh absent.
if [ -x "$HOME/.local/share/pantry/global/bin/gh" ]; then
  ln -sf "$HOME/.local/share/pantry/global/bin/gh" "$HOME/.local/bin/gh"
  echo "    ✓ gh -> $HOME/.local/bin/gh"
fi

# Ensure a Den-capable Zig. Den needs the exact 0.17-dev build pinned in
# deps.yaml. Older Pantry releases resolve versions from a baked-in snapshot that
# predates that build and silently install an older dev build that can't compile
# Den, so if the Zig on PATH isn't the pinned one, fetch the pinned dev build
# straight from Pantry's registry CDN (which has it) into the user-global bin.
ZIG_PIN="$(awk -F': *' '/ziglang.org:/ {print $2}' "$DOTFILES/deps.yaml" | awk '{print $1}')"
if [ -n "$ZIG_PIN" ] && ! zig version 2>/dev/null | grep -q "${ZIG_PIN%%[+_]*}"; then
  echo "==> Fetching pinned Zig ($ZIG_PIN)..."
  case "$(uname -m)" in
    arm64|aarch64) ZARCH="darwin-arm64"; ZIGARCH="aarch64-macos" ;;
    *)             ZARCH="darwin-x86-64"; ZIGARCH="x86_64-macos" ;;
  esac
  ZDIR="$HOME/.local/share/pantry/global"
  ZTMP="$(mktemp -d)"
  # Source 1: Pantry's registry (.tar.gz). Source 2: ziglang.org's official
  # build (.tar.xz) — covers dev builds Pantry's registry hasn't published yet.
  # `tar xf` auto-detects gzip vs xz.
  if ! curl -fsSL "https://registry.pantry.dev/binaries/ziglang.org/$ZIG_PIN/$ZARCH/ziglang.org-$ZIG_PIN.tar.gz" -o "$ZTMP/zig.tar" 2>/dev/null; then
    curl -fsSL "https://ziglang.org/builds/zig-$ZIGARCH-$ZIG_PIN.tar.xz" -o "$ZTMP/zig.tar" 2>/dev/null || true
  fi
  if [ -s "$ZTMP/zig.tar" ] && tar xf "$ZTMP/zig.tar" -C "$ZTMP" 2>/dev/null; then
    # Layout differs by source: ziglang.org ships <root>/zig + <root>/lib, while
    # Pantry ships <root>/bin/zig + <root>/lib. Copy the dir that holds zig's
    # lib/ and symlink to wherever the binary actually lands.
    ZBIN="$(find "$ZTMP" -type f -name zig -maxdepth 3 | head -1)"
    ZROOT="$(dirname "$ZBIN")"
    [ -d "$ZROOT/lib" ] || ZROOT="$(dirname "$ZROOT")"
    if [ -n "$ZBIN" ] && [ -d "$ZROOT/lib" ]; then
      DEST="$ZDIR/packages/ziglang.org/manual-$ZIG_PIN"
      rm -rf "$DEST"; mkdir -p "$DEST" "$ZDIR/bin"
      cp -R "$ZROOT/." "$DEST/"
      ln -sf "$(find "$DEST" -type f -name zig -maxdepth 2 | head -1)" "$ZDIR/bin/zig"
    fi
  else
    echo "    ! could not fetch Zig $ZIG_PIN — Den build may fail. Continuing." >&2
  fi
  rm -rf "$ZTMP"
fi
if ! zig version 2>/dev/null | grep -q '^0\.17'; then
  echo "WARNING: 'zig' is not 0.17.x — Den won't build. Check the ziglang.org pin in deps.yaml." >&2
fi

# 4. Build & install Den (the shell). Clone over SSH (git@) — Den is private, so
#    HTTPS would prompt for a password and fail (GitHub dropped password auth).
#    ssh.sh has already put your key on GitHub, so SSH just works. Den's build is
#    non-fatal: if Zig isn't new enough yet, keep going so the secrets/.env/SSH
#    recovery below still runs — you can rebuild Den later with `bun run den`.
if [ ! -d "$CODE/Tools/den" ]; then
  echo "==> Cloning Den (SSH)..."
  mkdir -p "$CODE/Tools"
  git clone git@github.com:home-lang/den.git "$CODE/Tools/den" \
    || echo "    ! could not clone Den — check 'ssh -T git@github.com'. Skipping Den build."
fi
if [ -d "$CODE/Tools/den" ]; then
  echo "==> Building Den..."
  ( cd "$CODE/Tools/den" && zig build -Doptimize=ReleaseFast ) || true
  # Symlink the den binary if the build produced it. Den ships example targets
  # that may lag the pinned Zig; the shell binary itself builds first, so a
  # failed example shouldn't stop us linking a working `den`.
  if [ -x "$CODE/Tools/den/zig-out/bin/den" ]; then
    ln -sf "$CODE/Tools/den/zig-out/bin/den" "$HOME/.local/bin/den"
    echo "    ✓ den -> $HOME/.local/bin/den"
  else
    echo "    ! Den build did not produce a binary (often a Zig version mismatch). Continuing." >&2
    echo "      Check the ziglang.org pin in deps.yaml, then: cd ~/Code/Tools/den && zig build -Doptimize=ReleaseFast" >&2
  fi
fi

# 5. Symlink shell configs.
ln -sf "$DOTFILES/.denrc" "$HOME/.denrc"                          # Den shell startup
ln -sf "$DOTFILES/.config/den.jsonc" "$HOME/.config/den.jsonc"    # Den declarative config
rm -f "$HOME/.zshrc"; ln -sf "$DOTFILES/.zshrc" "$HOME/.zshrc"    # zsh fallback

# 5b. Make Den the login shell — the primary daily-driver shell. Registers the
#     binary in /etc/shells (needs sudo) then chsh's to it; both are idempotent.
#     Recovery if Den ever misbehaves: Terminal → Settings → "Shells open with"
#     → /bin/zsh, or `chsh -s /bin/zsh`. The zsh fallback above keeps working.
DEN_BIN="$HOME/.local/bin/den"
if [ -x "$DEN_BIN" ]; then
  grep -qxF "$DEN_BIN" /etc/shells 2>/dev/null || echo "$DEN_BIN" | sudo tee -a /etc/shells >/dev/null
  if [ "$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')" != "$DEN_BIN" ]; then
    chsh -s "$DEN_BIN" && echo "    ✓ login shell set to Den"
  fi
fi
ln -sf "$DOTFILES/.gitignore_global" "$HOME/.gitignore_global"    # global gitignore
git config --global core.excludesfile "$HOME/.gitignore_global"  # (user/email come from recovery)

# 6. Recover EVERYTHING from iCloud in one shot: credentials, .env files and app
#    settings, then every repo cloned back to its original ~/Code path with all
#    local-only git work (unpushed commits, stashes, uncommitted, untracked),
#    then any remaining org repos, then your mail accounts (opens the generated
#    profile + Internet Accounts to finish). See bin/dot-recover. Requires iCloud
#    Drive to be signed in and synced; if it isn't here yet we skip with instructions.
ICLOUD_BK="$HOME/Library/Mobile Documents/com~apple~CloudDocs/ts-backups"
if [ -d "$ICLOUD_BK" ]; then
  # Full recovery: restores ~/.ssh (keys + the host configs you SSH into),
  # ~/.config/gh (so gh is authed), ~/.aws, every project's .env files, then
  # clones all your repos. This is where the "ssh into machines / .env" setup
  # comes from — see .config/backups.ts for the full list.
  "$DOTFILES/bin/dot-recover" || echo "    (recover reported problems — review output above)"
else
  # No iCloud yet: we can't restore secrets/.env, but we can still clone all your
  # repos over SSH so the machine is usable. clone.sh needs gh to list org repos;
  # authenticate it now (the keyring token doesn't transfer between machines).
  echo "==> No iCloud backup found yet — skipping secret/.env restore."
  if command -v gh >/dev/null 2>&1 && ! gh auth status >/dev/null 2>&1; then
    echo "==> Authenticating gh (needed to clone your org repos)..."
    gh auth login --git-protocol ssh --hostname github.com \
      || echo "    (skipped gh auth — run 'gh auth login' later, then 'sh clone.sh')"
  fi
  echo "==> Cloning your repositories (Pantry, Den, org repos)..."
  sh "$DOTFILES/clone.sh" || echo "    (clone.sh reported problems — review output above)"
  echo "==> Once iCloud has synced, restore secrets/.env & mail with:"
  echo "    cd ~/.dotfiles && bun run recover"
fi

# 7. macOS defaults — reloads the shell, so run this last.
echo "==> Applying macOS defaults..."
. "$DOTFILES/.macos"

cat <<'EOF'

All done! Next steps:
  - Open a new terminal and run `den` (or point your terminal app at ~/.local/bin/den).
  - GUI apps & fonts come from apps.yaml / fonts.yaml (installed natively by
    'pantry install' above; Mac App Store apps install silently via CommerceKit —
    no App Store window — as long as you're signed in and approved sudo).
  - Mail: recovery set up your accounts. Approve the staged profile (System
    Settings → General → Device Management) and sign into Gmail/iCloud in the
    Internet Accounts window it opened. (Re-run anytime: `bun run mail`.)
  - If recovery was skipped (iCloud not synced) or gh wasn't authed, finish with:
        gh auth login          # if cloning needs it
        cd ~/.dotfiles && bun run recover   # also sets up mail
  - Keep your off-machine copy fresh before the NEXT wipe with:
        cd ~/.dotfiles && bun run prewipe      # = backup (secrets) + rescue (git work)
  - Den is now your login shell (step 5b chsh'd to it). Open a new terminal to
    land in Den. Recovery if needed: Terminal → Settings → "Shells open with"
    → /bin/zsh, or `chsh -s /bin/zsh` — the zsh fallback config still works.
EOF
