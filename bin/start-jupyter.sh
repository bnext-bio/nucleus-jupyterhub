#!/bin/zsh

exec /usr/local/bin/start-singleuser.py "$@" |& tee /home/jovyan/.log/`date -Iseconds`-jupyter.log