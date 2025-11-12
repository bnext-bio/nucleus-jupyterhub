#!/bin/bash

# Provide a devnote selector because Jupyter App Launcher doesn't have an easy way to operated
# in the CWD selected in the file browser.
set -eo pipefail

if [ ! -f ~/.curvenote/settings.json ]; then
    echo "Please set up your curvenote token."
    echo "Go to https://curvenote.com/"
fi

cd ~/work/devnotes
cd `ls -d ./*/ | fzf`
curvenote submit bnext-devnotes --yes --collection nucleus-contrib $1