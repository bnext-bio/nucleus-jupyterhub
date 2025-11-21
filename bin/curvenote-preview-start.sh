#!/usr/bin/zsh

# Flag to track if we should exit
SHOULD_EXIT=0

# Trap handler for clean exit
cleanup() {
  echo "Cleanly exiting curvenote start: PID $$"
  SHOULD_EXIT=1
  # Kill the curvenote process if it's still running
  if [[ -n "$CURVENOTE_PID" ]] && kill -0 "$CURVENOTE_PID" 2>/dev/null; then
    kill "$CURVENOTE_PID" 2>/dev/null
  fi
}

trap cleanup SIGINT SIGTERM

while [[ $SHOULD_EXIT -eq 0 ]]; do
  echo "Starting Curvenote"
  HOST=127.0.0.1 curvenote -d start "$@" &
  CURVENOTE_PID=$!
  
  # Wait for the process and capture its exit status
  wait "$CURVENOTE_PID"
  EXIT_STATUS=$?
  
  # Check if we should exit (signal received)
  if [[ $SHOULD_EXIT -eq 1 ]]; then
    break
  fi
  
  sleep 5
  echo "Curvenote quit: potential breaking error."
done

echo "Script terminated"