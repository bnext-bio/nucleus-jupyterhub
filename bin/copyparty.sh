#!/usr/bin/zsh

set -uo pipefail

cd $HOME
uvx --with pillow copyparty -c ~/.config/copyparty.conf --rp-loc ${JUPYTERHUB_SERVICE_PREFIX}proxy/absolute/3923