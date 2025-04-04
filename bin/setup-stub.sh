#!/bin/bash

LOG_FILE=/home/jovyan/work/.log/`date -Iseconds`-setup.log

echo "In setup-stub: logging to $LOG_FILE"

mkdir -p `dirname $LOG_FILE`
/bin/bash /opt/repo/bin/setup.sh |& tee ${LOG_FILE}