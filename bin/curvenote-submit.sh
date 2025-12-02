#!/bin/bash

set -eo pipefail

if [ ! -f ~/.curvenote/settings.json ]; then
    echo "Please set up your curvenote token."
    echo "Go to https://editor.curvenote.com/profile"
fi

curvenote submit bnext-devnotes --yes --collection nucleus-contrib $1