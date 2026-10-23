#!/usr/bin/env bash

# Stop the script if a command fails unexpectedly.
set -e

# Move to the project root, regardless of where the script is called from.
cd "$(dirname "$0")/.."
SERVER_PID=""

cleanup() {
  if [ -n "$SERVER_PID" ]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
}

trap cleanup EXIT

echo "=================================="
echo " ReleaseGuard: Release Simulation"
echo "=================================="
# Start the candidate release in the background.
echo ""
echo "Starting the candidate release..."

RELEASE_MODE=broken node app/server.js &
SERVER_PID=$!

sleep 2

echo ""
echo "Running release verification..."

if npm test; then
  echo "Candidate release passed verification."
else
  echo "Candidate release FAILED verification."
  echo "Starting recovery..."

  kill "$SERVER_PID" 2>/dev/null || true
  wait "$SERVER_PID" 2>/dev/null || true

  echo "Starting the known-good release..."
  RELEASE_MODE=healthy node app/server.js &
  SERVER_PID=$!

  sleep 2

  echo "Verifying the recovered release..."

  if npm test; then
    echo "RECOVERY SUCCESSFUL: known-good release passed."
  else
    echo "RECOVERY FAILED: known-good release did not pass."
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
    exit 1
  fi
fi

kill "$SERVER_PID" 2>/dev/null || true
wait "$SERVER_PID" 2>/dev/null || true

echo ""
echo "Release simulation complete."
