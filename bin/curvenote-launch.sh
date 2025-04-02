#!/bin/bash

CURVENOTE_BUILD=/opt/repo/bin/curvenote-build.sh
HTML_DIR=~/work/devnotes/.html

mkdir -p $HTML_DIR
caddy file-server --listen :$1 --browse -r $HTML_DIR &
nodemon -w ~/work/devnotes/ -i _build/ -i .html/ --ext md,yml,json,ipynb,html -x $CURVENOTE_BUILD &