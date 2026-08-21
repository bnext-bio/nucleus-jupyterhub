#!/bin/bash

set -eo pipefail

if [ ! -f ~/.curvenote/settings.json ]; then
    echo "Please set up your curvenote token."
    echo "Go to https://editor.curvenote.com/profile"
fi

# cd into home directory using relative path passed through from launcher.
if [[ -d $1 ]]; then
    cd ~/$1
fi

curvenote submit bnext-devnotes --yes --collection nucleus-contrib $2