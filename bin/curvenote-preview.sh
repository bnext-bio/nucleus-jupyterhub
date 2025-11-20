#!/usr/bin/zsh

set -euo pipefail

LOG_FILE="/tmp/preview.`date -Iseconds`"
PORT=$1
THEME_PORT=$((PORT + 1))
CONTENT_PORT=$((THEME_PORT + 100))

PROXY_BASE="${JUPYTERHUB_SERVICE_PREFIX}proxy"

cat <<EOF > ${LOG_FILE}.log
Starting Curvenote Preview
   Proxy Port: ${PORT}
   Theme Port: ${THEME_PORT}
 Content Port: ${CONTENT_PORT}
EOF

function cleanup() {
  echo Quitting preview server: $1 ${curvenote_pid} >> ${LOG_FILE}.log
  kill $curvenote_pid > /dev/null 2>&1
  sleep 5
  kill -9 $curvenote_pid > /dev/null 2>&1
  exit
}

trap "cleanup $1" SIGINT SIGTERM EXIT

cd ~/devnotes/template
#cd `ls -d ./*/ | fzf`

HOST=127.0.0.1 curvenote -d start --port ${THEME_PORT} --server-port ${CONTENT_PORT} > ${LOG_FILE}.curvenote.log 2>&1 &
curvenote_pid=$!

sleep 2
curl -s --connect-timeout 10 http://localhost:${THEME_PORT}/ > /dev/null

cat <<EOF | caddy run --adapter caddyfile --config - >> ${LOG_FILE}.log 2>&1
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
                #re "\\$\{i\}:\\$\{t.port\}/socket" "localhost:8000${PROXY_BASE}/${CONTENT_PORT}/socket"
        }

        reverse_proxy localhost:${THEME_PORT} {
                header_up Accept-Encoding identity
        }
}
EOF