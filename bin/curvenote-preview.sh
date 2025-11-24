#!/usr/bin/zsh
set -uo pipefail
PORT=$1
THEME_PORT=$((PORT + 1))
CONTENT_PORT=$((THEME_PORT + 100))
PROXY_BASE="${JUPYTERHUB_SERVICE_PREFIX}proxy"

LOG_DIR="/tmp/preview.`date -Iseconds`"
mkdir -p ${LOG_DIR}

ln -s /opt/repo/share/caddy/* ${LOG_DIR}

cat <<EOF > ${LOG_DIR}/preview.log
Starting Curvenote Preview
   Proxy Port: ${PORT}
   Theme Port: ${THEME_PORT}
 Content Port: ${CONTENT_PORT}
EOF

SHOULD_EXIT=0
curvenote_pid=""
caddy_pid=""

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
  echo "Target PIDS: curvenote:$curvenote_pid caddy:$caddy_pid" >> ${LOG_DIR}/preview.log

  for sig in ""; do  # Don't SIGKILL because it prevents proper node shutdown
    # Kill curvenote
    if [[ -n "$curvenote_pid" ]] && kill -0 $curvenote_pid 2>/dev/null; then
      echo "Killing ${sig} curvenote PID ${curvenote_pid}" >> ${LOG_DIR}/preview.log
      kill_tree $curvenote_pid || true
      kill $sig $curvenote_pid 2>/dev/null || true
    fi
    
    # Kill caddy
    if [[ -n "$caddy_pid" ]] && kill -0 $caddy_pid 2>/dev/null; then
      echo "Killing ${sig} caddy PID ${caddy_pid}" >> ${LOG_DIR}/preview.log
      kill $sig $caddy_pid 2>/dev/null || true
    fi

    sleep 1
  done

  # Cleanup PID files
  rm -f ${LOG_DIR}/*.pid || true
  
  exit
}

trap "cleanup $1" SIGINT SIGTERM

cd ~/devnotes/template

# Start Caddy in the background (not foreground) so we can wait on it
cat <<EOF | caddy run --adapter caddyfile --config - >> ${LOG_DIR}/preview.log 2>&1 &
{
  debug
  auto_https off
}
http://:${PORT} {
  replace {
    re "http://localhost:([0-9]+)" "${PROXY_BASE}/\$1"
    re "/myst_assets_folder" "${PROXY_BASE}/${PORT}/myst_assets_folder"
    re "/favicon.ico" "${PROXY_BASE}/${PORT}/favicon.ico"
    re "/myst-theme.css" "${PROXY_BASE}/${PORT}/myst-theme.css"
    re "/thebe-core.min.js" "${PROXY_BASE}/${PORT}/thebe-core.min.js"
    re "/api" "${PROXY_BASE}/${PORT}/api"
    re "\"path\":\"\"" "\"path\":\"${PROXY_BASE}/${PORT}/\""
    re ":\\$\{t.port\}/socket" "${PROXY_BASE}/${CONTENT_PORT}/socket"
  }

  reverse_proxy localhost:${THEME_PORT} {
    header_up Accept-Encoding identity
    header_down Cache-Control no-store
  }

  handle_errors {
    rewrite * /error.html
    templates {
      root ${LOG_DIR}
    }
    file_server {
      root ${LOG_DIR}
      status 200
    }
  }
}
EOF
caddy_pid=$!
echo ${curvenote_pid} > ${LOG_DIR}/caddy.pid
echo "Caddy PID is ${caddy_pid}" >> ${LOG_DIR}/preview.log

# Monitor curvenote in background and restart if needed
while [[ $SHOULD_EXIT -eq 0 ]]; do
  if ! kill -0 $curvenote_pid 2>/dev/null; then
    if [[ $SHOULD_EXIT -eq 0 ]]; then
      echo "Starting curvenote" >> ${LOG_DIR}/preview.log

      HOST=127.0.0.1 curvenote -d start --port ${THEME_PORT} --server-port ${CONTENT_PORT} >> ${LOG_DIR}/curvenote.log 2>&1 &
      curvenote_pid=$!

      echo "Curvenote PID is ${curvenote_pid}" >> ${LOG_DIR}/preview.log
      echo ${curvenote_pid} > ${LOG_DIR}/curvenote.pid

      sleep 2
      curl -s --connect-timeout 10 http://localhost:${THEME_PORT}/ > /dev/null || echo Failed to connect to theme server >> ${LOG_DIR}/preview.log
      curl -s --connect-timeout 10 http://localhost:${CONTENT_PORT}/ > /dev/null || echo Failed to connect to theme server >> ${LOG_DIR}/preview.log
      echo "Curvenote started" >> ${LOG_DIR}/preview.log

      sleep 5
      touch ${LOG_DIR}/curvenote.started
    fi
  fi

  wait $curvenote_pid
  sleep 5
done

cleanup $1