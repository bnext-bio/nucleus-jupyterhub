#!/bin/bash

cd $1

export HOST=127.0.0.1
export BASE_PATH=${JUPYTERHUB_SERVICE_PREFIX}proxy/absolute/$2

LOG_DIR="/tmp/preview.`date -Iseconds`"
mkdir -p ${LOG_DIR}

cat <<EOF > ${LOG_DIR}/preview.log
`date -Iseconds`
Cwd: `pwd`
Port: $2
Host: $HOST
Base: $BASE_PATH
EOF

# If we are in a subdirectory, try to find the DevNote parent directory
cd "${DEVNOTE_DIR}"
CURVENOTE_YAML="$(echo (../)#curvenote.yml(N:a))"

if [[ -n "${CURVENOTE_YAML}" && -f "${CURVENOTE_YAML}" ]]; then
  echo "curvenote.yml found at ${CURVENOTE_YAML}" >> ${LOG_DIR}/preview.log

  DEVNOTE_DIR="$(dirname $CURVENOTE_YAML)"
  cd "$DEVNOTE_DIR"

  ln -s "${CURVENOTE_YAML}" ${LOG_DIR}/curvenote.yml
  cat "${CURVENOTE_YAML}" | yq ".project.title" > ${LOG_DIR}/curvenote.title
else
  echo "No curvenote.yml found" >> ${LOG_DIR}/preview.log
fi

/opt/conda/bin/curvenote start --port $2 > ${LOG_DIR}/curvenote.log 2>&1