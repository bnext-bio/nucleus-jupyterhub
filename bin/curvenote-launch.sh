#!/bin/bash

CURVENOTE_BUILD=/opt/repo/bin/curvenote-build.sh
HTML_DIR=~/work/devnotes/.html
LOG_FILE=~/work/.log/curvenote.log

echo "============" | tee -a ${LOG_FILE}
echo `date -Iseconds` | tee -a ${LOG_FILE}
echo "Launching curvenote preview proxy" | tee -a ${LOG_FILE}
echo "BASE_URL_PREFIX: ${BASE_URL_PREFIX}" | tee -a ${LOG_FILE}

cd ~/work/devnotes/
mkdir -p $HTML_DIR

# Prelaunch curvenote build so stuff is ready when we get redirected to the website
/bin/bash -c "${CURVENOTE_BUILD}" | tee -a ${LOG_FILE}

caddy file-server --listen :$1 --browse --root $HTML_DIR/ | tee -a ${LOG_FILE} &
nodemon -w ~/work/devnotes/ -i _build/ -i .html/ --ext md,yml,json,ipynb,html -x $CURVENOTE_BUILD | tee -a ${LOG_FILE} &