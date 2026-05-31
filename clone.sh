#!/bin/sh
# clone.sh — clone the repositories used on a fresh machine.
#
# Note: the old zsh plugin clones (zsh-autosuggestions, zsh-syntax-highlighting,
# fast-syntax-highlighting, zsh-autocomplete) were removed — Den provides
# autosuggestions, syntax highlighting, completion and history search natively.

echo "Cloning repositories..."

SITES="$HOME/Code"
mkdir -p "$SITES"

# Open Web
git clone git@github.com:stacksjs/stacks.git "$SITES/stacks"
git clone git@github.com:stacksjs/ts-starter.git "$SITES/ts-starter"
git clone git@github.com:stacksjs/dynamodb-tooling.git "$SITES/dynamodb-tooling"
git clone git@github.com:stacksjs/tlsx.git "$SITES/tlsx"
git clone git@github.com:stacksjs/reverse-proxy.git "$SITES/reverse-proxy"
