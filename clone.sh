#!/bin/sh

echo "Cloning repositories..."

SITES=$HOME/Code

# Open Web
git clone git@github.com:stacksjs/stacks.git $SITES/stacks
git clone git@github.com:stacksjs/ts-starter.git $SITES/ts-starter
git clone git@github.com:stacksjs/dynamodb-tooling.git $SITES/dynamodb-tooling
git clone git@github.com:stacksjs/tlsx.git $SITES/tlsx
git clone git@github.com:stacksjs/reverse-proxy.git $SITES/reverse-proxy

# Plugins
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git $ZSH_CUSTOM/plugins/zsh-autocomplete