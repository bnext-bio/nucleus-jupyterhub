#!/usr/bin/zsh
set -uo pipefail
setopt extendedglob

DEVNOTE_DIR="$1"
PORT="$2"

LOG_DIR="/tmp/preview.`date -Iseconds`"
mkdir -p ${LOG_DIR}

cat <<EOF > ${LOG_DIR}/preview.log
Starting Curvenote Live Preview
          CWD: `pwd`
         Args: ${@}
         Port: ${PORT}
         Content Port: ${CONTENT_CDN_PORT}
EOF

SHOULD_EXIT=0
curvenote_pid=""

# Unreasonable amount of cleanup housekeeping to stop
# the forked content server from staying alive when we
# shutdown curvenote. This only happens when it's directly
# launched by the jupyter launcher, not if you launch the 
# script from a shell. Could be related to different session/
# PGID behavior.

kill_tree() {
    local pid=$1
    local sig=${2:-TERM}
    
    # Get all children first
    local children=$(pgrep -P $pid)
    
    # Recursively kill all children first
    for child in $children; do
        kill_tree $child $sig
    done
    
    # Then kill the parent
    kill -$sig $pid 2>/dev/null
}

function cleanup() {
  if [[ $SHOULD_EXIT -eq 1 ]]; then
    return  # Prevent multiple cleanup calls
  fi
  SHOULD_EXIT=1
  
  echo "Quitting preview server: $1" >> ${LOG_DIR}/preview.log
  echo "Target PID: curvenote:$curvenote_pid" >> ${LOG_DIR}/preview.log

  # Kill curvenote and all its children
  if [[ -n "$curvenote_pid" ]] && kill -0 $curvenote_pid 2>/dev/null; then
    echo "Killing curvenote PID ${curvenote_pid}" >> ${LOG_DIR}/preview.log
    kill_tree $curvenote_pid || true
    kill $curvenote_pid 2>/dev/null || true
  fi

  sleep 1

  # Cleanup PID files
  rm -f ${LOG_DIR}/*.pid || true
  
  exit
}

trap "cleanup $1" SIGINT SIGTERM

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

echo "${DEVNOTE_DIR}" > ${LOG_DIR}/preview.cwd

# Monitor curvenote in background and restart if needed
while [[ $SHOULD_EXIT -eq 0 ]]; do
  if ! kill -0 $curvenote_pid 2>/dev/null; then
    if [[ $SHOULD_EXIT -eq 0 ]]; then
      echo "Starting curvenote" >> ${LOG_DIR}/preview.log

      # Run curvenote directly on the assigned port
      # Curvenote will handle its own internal content server port
      HOST=127.0.0.1 BASE_PATH=${PROXY_BASE}/${PORT} curvenote -d start --port ${PORT} --server-port ${CONTENT_PORT} >> ${LOG_DIR}/curvenote.log 2>&1 &
      curvenote_pid=$!

      echo "Curvenote PID is ${curvenote_pid}" >> ${LOG_DIR}/preview.log
      echo ${curvenote_pid} > ${LOG_DIR}/curvenote.pid

      sleep 2
      curl -s --connect-timeout 10 --retry 10 --retry-connrefused http://localhost:${PORT}/ > /dev/null || echo Failed to connect to curvenote server >> ${LOG_DIR}/preview.log
      echo "Curvenote started on port ${PORT}" >> ${LOG_DIR}/preview.log
      touch ${LOG_DIR}/curvenote.started
    fi
  fi

  wait $curvenote_pid
  sleep 5
done

cleanup $1