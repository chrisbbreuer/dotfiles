#!/bin/sh

echo "Cloning repositories..."

SITES=$HOME/Code

# Meema projects
git clone git@github.com:meemalabs/meema.io.git $SITES/meema.io
git clone git@github.com:meemalabs/meema-api.git $SITES/meema-api
git clone git@github.com:meemalabs/media-manager.git $SITES/meema-media-manager
git clone git@github.com:meemalabs/meema-client-php.git $SITES/meema-client-php
git clone git@github.com:meemalabs/meema.js.git $SITES/meema.js
git clone git@github.com:meemalabs/laravel-meema.git $SITES/laravel-meema
git clone git@github.com:meemalabs/laravel-file-preview.git $SITES/laravel-file-preview
git clone git@github.com:meemalabs/flysystem-meema.git $SITES/flysystem-meema

# Meema OS projects
git clone git@github.com:meemalabs/laravel-text-to-speech.git $SITES/laravel-text-to-speech
git clone git@github.com:meemalabs/laravel-media-recognition.git $SITES/laravel-media-recognition
git clone git@github.com:meemalabs/laravel-media-converter.git $SITES/laravel-media-converter
git clone git@github.com:meemalabs/laravel-cloudfront.git $SITES/laravel-cloudfront

# OW3 OS projects
git clone git@github.com:openwebstacks/stacks-framework.git $SITES/stacks-framework
git clone git@github.com:openwebstacks/vue-starter.git $SITES/vue-starter
git clone git@github.com:openwebstacks/ts-starter.git $SITES/ts-starter
git clone git@github.com:openwebstacks/web-components-starter.git $SITES/web-components-starter
git clone git@github.com:openwebstacks/composable-starter.git $SITES/composable-starter
git clone git@github.com:openwebstacks/table-stack.git $SITES/table-stack
git clone git@github.com:openwebstacks/date-picker-stack.git $SITES/date-picker-stack
git clone git@github.com:openwebstacks/web3-stack.git $SITES/web3-stack

# CION
git clone git@github.com:ci-on/cion.agency.git $SITES/cion.agency
