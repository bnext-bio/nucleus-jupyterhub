#!/bin/bash

CURVENOTE_BUILD=/opt/repo/bin/curvenote-build.sh
HTML_DIR=~/work/devnotes/.html

echo "============" | tee -a ~/work/.log/curvenote.log
echo `date -Iseconds` | tee -a ~/work/.log/curvenote.log
echo "Launching curvenote preview proxy" | tee -a ~/work/.log/curvenote.log
echo "BASE_URL_PREFIX: ${BASE_URL_PREFIX}" | tee -a ~/work/.log/curvenote.log

cd ~/work/devnotes/
mkdir -p $HTML_DIR
caddy file-server --listen :$1 --browse -r $HTML_DIR | tee -a ~/work/.log/curvenote.log &
nodemon -w ~/work/devnotes/ -i _build/ -i .html/ --ext md,yml,json,ipynb,html -x $CURVENOTE_BUILD | tee -a ~/work/.log/curvenote.log &