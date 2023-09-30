#!/bin/sh

echo "Cloning repositories..."

SITES=$HOME/Code

# Open Web
git clone git@github.com:stacksjs/stacks.git $SITES/stacks
git clone git@github.com:ow3org/vue-starter.git $SITES/vue-starter
git clone git@github.com:ow3org/ts-starter.git $SITES/ts-starter
git clone git@github.com:ow3org/web-components-starter.git $SITES/web-components-starter
git clone git@github.com:ow3org/composable-starter.git $SITES/composable-starter

# CION
git clone git@github.com:ci-on/cion.agency.git $SITES/cion.agency
