#!/bin/zsh

exec /usr/local/bin/start-singleuser.py "$@" |& tee ${HOME}/.log/`date -Iseconds`-jupyter.log