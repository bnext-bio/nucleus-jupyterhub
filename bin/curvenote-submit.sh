#!/bin/bash

# Provide a devnote selector because Jupyter App Launcher doesn't have an easy way to operated
# in the CWD selected in the file browser.
set -exo pipefail

cd ~/work/devnotes
cd `ls -d ./*/ | ~/.fzf/bin/fzf`
curvenote submit bnext-devnotes --yes --collection nucleus-contrib $1