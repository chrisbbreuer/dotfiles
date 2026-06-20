#!/bin/sh
# clone.sh — clone every repository we work on onto a fresh machine.
#
# Clones all non-fork repos from the orgs below into ~/Code/<org>/<repo>, plus
# any one-off EXTRA_REPOS. Cloning is over SSH, so it covers private repos as
# long as your SSH key is already in place — restore it first (fresh.sh does
# this before calling clone.sh). Listing repos needs `gh` to be authenticated.
#
# Idempotent: a repo whose directory already exists ANYWHERE shallow under
# ~/Code (e.g. an existing flat checkout like ~/Code/stacks, ~/Code/den, or
# ~/Code/Libraries/ts-backups) is skipped, so this never clobbers or duplicates
# your existing work — it only fills in what's missing.
set -e

CODE="$HOME/Code"
# Every repo in these orgs gets cloned.
ORGS="stacksjs home-lang cwcss zig-utils"
# Individual repos outside those orgs (owner/repo, space-separated).
EXTRA_REPOS=""

mkdir -p "$CODE"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh (GitHub CLI) not found — run 'pantry install' first, then re-run clone.sh." >&2
  exit 0
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated." >&2
  echo "Run 'gh auth login' (the keyring token doesn't transfer between machines)," >&2
  echo "then re-run:  sh ~/.dotfiles/clone.sh" >&2
  exit 0
fi

# True when a directory named $1 already exists shallowly under ~/Code.
repo_present() {
  find "$CODE" -maxdepth 3 -type d -name "$1" -print -quit 2>/dev/null | grep -q .
}

clone_one() {
  # $1 = owner/repo
  name=${1#*/}
  if repo_present "$name"; then
    echo "  ✓ $name already present — skipping"
    return 0
  fi
  dest="$CODE/${1%%/*}/$name"
  echo "  ⬇ $1 -> $dest"
  git clone --quiet "git@github.com:$1.git" "$dest" || echo "    ! failed to clone $1" >&2
}

for org in $ORGS; do
  echo "==> $org"
  # --source = our own repos, not forks. Includes archived so we get everything.
  gh repo list "$org" --source --limit 1000 --json nameWithOwner -q '.[].nameWithOwner' \
    | while IFS= read -r repo; do
        [ -n "$repo" ] && clone_one "$repo"
      done
done

for repo in $EXTRA_REPOS; do
  [ -n "$repo" ] && clone_one "$repo"
done

echo "Done. Cloned org repositories into $CODE/<org>/."
