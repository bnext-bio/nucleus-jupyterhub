#!/usr/bin/zsh

set -uo pipefail

cd $HOME
uvx --with pillow --with mutagen copyparty -c ~/.config/copyparty.conf -p $1 --name "${USER} hub" --rp-loc ${JUPYTERHUB_SERVICE_PREFIX}copyparty/ |& tee /tmp/copyparty-`date -Iseconds`.log