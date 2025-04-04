#!/bin/bash

# Provide a devnote selector because Jupyter App Launcher doesn't have an easy way to operated
# in the CWD selected in the file browser.

cd ~/work/devnotes
cd `ls -d ./*/ | fzf`
curvenote submit bnext-devnotes --collection nucleus-contrib $1