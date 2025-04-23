#!/bin/bash

export REPO=/opt/repo
export LOG_FILE=/home/jovyan/work/.log/`date -Iseconds`-setup.log

echo "In setup-stub: logging to $LOG_FILE"
mkdir -p `dirname $LOG_FILE`

echo "Updating git repository: ${REPO}" | tee ${LOG_FILE}
if [ ! -d ${REPO} ]; then
    git clone --depth=1 ${GIT_REMOTE} ${REPO} |& tee ${LOG_FILE}
fi

cd ${REPO}
git remote set-url origin ${GIT_REMOTE} |& tee ${LOG_FILE} # Fix up remote if image was built from a repo with an SSH origin.
git pull |& tee ${LOG_FILE}

echo "Running main setup" | tee ${LOG_FILE}
/bin/bash /opt/repo/bin/setup.sh |& tee ${LOG_FILE}