#!/bin/sh
# ssh.sh — generate a GitHub SSH key and get it ready to use on a fresh Mac.
#
#   curl -fsSL https://raw.githubusercontent.com/chrisbbreuer/dotfiles/HEAD/ssh.sh | sh -s "you@example.com"
#
# Idempotent: re-running reuses an existing key instead of clobbering it.
# Docs: https://docs.github.com/en/authentication/connecting-to-github-with-ssh
set -e

EMAIL="${1:-$(git config --global user.email 2>/dev/null || echo)}"
KEY="$HOME/.ssh/id_ed25519"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# 1. Generate the key (only if it doesn't already exist).
if [ -f "$KEY" ]; then
  echo "==> Reusing existing SSH key at $KEY"
else
  echo "==> Generating a new ed25519 SSH key for GitHub..."
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY"
fi

# 2. ~/.ssh/config — load the key from the agent and store the passphrase in the
#    macOS keychain so you only type it once. Written idempotently.
if [ ! -f "$HOME/.ssh/config" ] || ! grep -q "IdentityFile ~/.ssh/id_ed25519" "$HOME/.ssh/config" 2>/dev/null; then
  echo "==> Writing ~/.ssh/config"
  cat >>"$HOME/.ssh/config" <<'EOF'
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
fi
chmod 600 "$HOME/.ssh/config"

# 3. Start the agent and add the key. `--apple-use-keychain` replaces the
#    deprecated `-K`; fall back to `-K` on older macOS that lacks the long flag.
echo "==> Adding the key to the ssh-agent (and macOS keychain)..."
eval "$(ssh-agent -s)" >/dev/null
ssh-add --apple-use-keychain "$KEY" 2>/dev/null \
  || ssh-add -K "$KEY" 2>/dev/null \
  || ssh-add "$KEY"

# 4. Pre-trust github.com so later `git clone` calls don't stop on an
#    interactive "are you sure you want to continue connecting?" prompt.
if ! ssh-keygen -F github.com >/dev/null 2>&1; then
  echo "==> Trusting github.com host key..."
  ssh-keyscan -t ed25519 github.com >>"$HOME/.ssh/known_hosts" 2>/dev/null || true
fi

# 5. Register the public key with GitHub. Prefer the gh CLI if it's already
#    installed (it isn't on a brand-new machine, but is on re-runs); otherwise
#    copy it to the clipboard and open the GitHub page so you can paste it.
PUB="$KEY.pub"
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  echo "==> Adding the public key to GitHub via gh..."
  gh ssh-key add "$PUB" --title "$(scutil --get ComputerName 2>/dev/null || hostname)" \
    || echo "    (gh could not add the key — add it manually below)"
else
  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy <"$PUB"
    echo "==> Public key copied to your clipboard."
  fi
  echo "    Add it to GitHub: https://github.com/settings/ssh/new"
  command -v open >/dev/null 2>&1 && open "https://github.com/settings/ssh/new" 2>/dev/null || true
  echo "    (key also lives at $PUB)"
fi

# 6. Confirm it works.
echo "==> Verifying GitHub SSH access..."
if ssh -T -o StrictHostKeyChecking=accept-new git@github.com 2>&1 | grep -q "successfully authenticated"; then
  echo "✅ SSH is set up — you can now: git clone git@github.com:chrisbbreuer/dotfiles.git ~/.dotfiles"
else
  echo "ℹ️  Once the key is on GitHub, test with: ssh -T git@github.com"
fi
