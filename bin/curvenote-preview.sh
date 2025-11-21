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

function cleanup() {
  if [[ $SHOULD_EXIT -eq 1 ]]; then
    return  # Prevent multiple cleanup calls
  fi
  SHOULD_EXIT=1
  
  echo "Quitting preview server: $1" >> ${LOG_DIR}/preview.log
  
  # Kill curvenote
  if [[ -n "$curvenote_pid" ]] && kill -0 $curvenote_pid 2>/dev/null; then
    echo "Killing curvenote PID ${curvenote_pid}" >> ${LOG_DIR}/preview.log
    kill $curvenote_pid 2>/dev/null || true
    sleep 1
    kill -9 $curvenote_pid 2>/dev/null || true
  fi
  
  # Kill caddy
  if [[ -n "$caddy_pid" ]] && kill -0 $caddy_pid 2>/dev/null; then
    echo "Killing caddy PID ${caddy_pid}" >> ${LOG_DIR}/preview.log
    kill $caddy_pid 2>/dev/null || true
    sleep 1
    kill -9 $caddy_pid 2>/dev/null || true
  fi

  # Cleanup PID files
  rm -f ${LOG_DIR}.curvenote.pid
  
  exit
}

trap "cleanup $1" SIGINT SIGTERM

cd ~/devnotes/template

# Function to start/restart curvenote
start_curvenote() {
  echo "Starting curvenote" >> ${LOG_DIR}/preview.log
  HOST=127.0.0.1 curvenote -d start --port ${THEME_PORT} --server-port ${CONTENT_PORT} > ${LOG_DIR}/curvenote.log 2>&1 &
  curvenote_pid=$!
  echo "Curvenote PID is ${curvenote_pid}" >> ${LOG_DIR}/preview.log
  echo ${curvenote_pid} > ${LOG_DIR}/curvenote.pid

  sleep 2
  curl -s --connect-timeout 10 http://localhost:${THEME_PORT}/ > /dev/null || echo Failed to connect to theme server >> ${LOG_DIR}/preview.log
  echo "Curvenote started" >> ${LOG_DIR}/preview.log
}

# Monitor curvenote in background and restart if needed
(
  while [[ $SHOULD_EXIT -eq 0 ]]; do
    if ! kill -0 $curvenote_pid 2>/dev/null; then
      if [[ $SHOULD_EXIT -eq 0 ]]; then
        start_curvenote
      fi
    fi
    sleep 5
  done
) &
monitor_pid=$!

# Start Caddy in the background (not foreground) so we can wait on it
cat <<EOF | caddy run --adapter caddyfile --config - >> ${LOG_DIR}/preview.log 2>&1 &
{
  debug
  auto_https off
}
http://localhost:${PORT} {
  replace {
    re "http://localhost:([0-9]+)" "${PROXY_BASE}/\$1"
    re "/myst_assets_folder" "${PROXY_BASE}/${PORT}/myst_assets_folder"
    re "/favicon.ico" "${PROXY_BASE}/${PORT}/favicon.ico"
    re "/myst-theme.css" "${PROXY_BASE}/${PORT}/myst-theme.css"
    re "/thebe-core.min.js" "${PROXY_BASE}/${PORT}/thebe-core.min.js"
    re "/api" "${PROXY_BASE}/${PORT}/api"
    re "\"path\":\"\"" "\"path\":\"${PROXY_BASE}/${PORT}/\""
    re ":\\$\{t.port\}/socket" ":8000${PROXY_BASE}/${CONTENT_PORT}/socket"
  }

  reverse_proxy localhost:${THEME_PORT} {
    header_up Accept-Encoding identity
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

# Wait for caddy to exit (either naturally or from a signal)
wait $caddy_pid
cleanup $1