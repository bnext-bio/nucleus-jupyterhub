#!/usr/bin/zsh

set -euo pipefail

cd /home/jovyan/devnotes

read "dirname?Enter a directory name for the DevNote: "
dirname="$(echo $dirname | tr '[:upper:]' '[:lower:]' | sed -r "s/[^[:alnum:]]/-/g" | sed -r "s/-+/-/g" | sed -r "s/-+$//g")"
echo "Creating DevNote in ${dirname}"

curvenote init --github https://github.com/antonrmolina/devnote-template --output ${dirname}