# Shortcuts
alias copyssh="pbcopy < $HOME/.ssh/id_ed25519.pub"
alias reloadshell="source $HOME/.zshrc"
alias reloaddns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias ls="/opt/homebrew/opt/coreutils/libexec/gnubin/ls"
# alias ll="/opt/homebrew/opt/coreutils/libexec/gnubin/ls -AhlFo --color --group-directories-first"
alias ll='exa --long --header --group --git --modified --color-scale --group-directories-first -a'
alias pstorm='open -a /Applications/PhpStorm.app "`pwd`"'
alias code='open -a "/Applications/Visual Studio Code.app" "`pwd`"'
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy"
# alias c="clear"
alias c="reset"
alias python=python3

# Directories
alias dotfiles="code $DOTFILES"
alias library="cd $HOME/Library"
alias web="cd $HOME/Code"
alias meema-api="web && cd meema-api/"
alias meema-manager="web && cd meema-media-manager/"
alias meema.io="web && cd meema.io/"

# Laravel
alias art="php artisan"
alias pfresh="php artisan migrate:fresh --seed"
alias sfresh="sail artisan migrate:fresh --seed"
alias pseed="php artisan db:seed"
alias sseed="sail artisan db:seed"
alias sail='[ -f sail ] && bash sail || bash vendor/bin/sail'
alias ptinker="php artisan tinker"
alias pserve="php artisan serve"

# PHP
alias cfresh="rm -rf vendor/ composer.lock && composer i"
alias composer="php -d memory_limit=-1 /opt/homebrew/bin/composer"
alias switch-php81="brew unlink php@8.1 && brew link --overwrite --force php"
alias switch-php80="brew unlink php && brew link --overwrite --force php@8.0"
alias switch-php74="brew unlink php && brew link --overwrite --force php@7.4"

# JS
alias nfresh="rm -rf node_modules/ package-lock.json && npm install"
alias yfresh="rm -rf node_modules/ yarn.lock && yarn"
alias pf="rm -rf node_modules/ pnpm-lock.yaml && pnpm i"
alias pfa="rimraf packages/**/node_modules && rimraf examples/**/node_modules node_modules/ pnpm-lock.yaml && pnpm i -r"
alias pi="pnpm i"
alias pia="pnpm i -r"
alias pid="pnpm i -D"
alias pc="pnpm run commit"
alias pr="pnpm run release"
alias pd="pnpm dev"
alias pt="pnpm typecheck"
alias pb="pnpm build"
alias pp="pnpm play"
alias pl="eslint"
alias plf="eslint . --fix"
alias p="pnpm "

# Docker
alias docker-composer="docker-compose"
alias docker-images-rm-all="docker image rm $(docker image ls -q)"

# SQL Server
alias mssql="docker run -e ACCEPT_EULA=Y -e SA_PASSWORD=LaravelWow1986! -p 1433:1433 mcr.microsoft.com/mssql/server:2017-latest"

# Git
alias gst="git status"
alias gb="git branch"
alias gc="git checkout"
alias gl="git log --oneline --decorate --color"
alias amend="git add . && git commit --amend --no-edit"
alias commit="git add . && git commit -m"
alias diff="git diff"
alias force="git push --force"
alias nah="git clean -df && git reset --hard"
alias pop="git stash pop"
alias pull="git pull"
alias push="git push"
alias resolve="git add . && git commit --no-edit"
alias stash="git stash -u"
alias unstage="git restore --staged ."
alias wip="commit 'chore: wip'; push"

# Show/hide hidden files in Finder
alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# Fix/Unstick macOS Touch Bar when it freezes
alias ft="killall ControlStrip && pkill 'Touch Bar agent'"

# IP addresses
alias ip="curl https://diagnostic.opendns.com/myip ; echo"
alias localip="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

# Empty the Trash on all mounted volumes and the main HDD
# Also, clear Apple’s System Logs to improve shell startup speed
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl"

# Enable aliases to be sudo’ed
alias sudo='sudo '
