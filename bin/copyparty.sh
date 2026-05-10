#!/usr/bin/zsh

set -uo pipefail

cd $HOME
uvx --with pillow copyparty -c ~/.config/copyparty.conf -p $1 --rp-loc ${JUPYTERHUB_SERVICE_PREFIX}copyparty/ |& tee /tmp/copyparty-`date -Iseconds`.log