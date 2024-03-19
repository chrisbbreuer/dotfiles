#!/bin/sh

echo "Cloning repositories..."

SITES=$HOME/Code

# Open Web
git clone git@github.com:stacksjs/stacks.git $SITES/stacks
git clone git@github.com:stacksjs/ts-starter.git $SITES/ts-starter
git clone git@github.com:stacksjs/dynamodb-tooling.git $SITES/dynamodb-tooling
git clone git@github.com:stacksjs/tlsx.git $SITES/tlsx
git clone git@github.com:stacksjs/reverse-proxy.git $SITES/reverse-proxy
