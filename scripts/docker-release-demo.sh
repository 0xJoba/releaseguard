#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/.."

CANDIDATE_CONTAINER="releaseguard-candidate"
RECOVERY_CONTAINER="releaseguard-recovery"
CANDIDATE_PORT=3001
RECOVERY_PORT=3002
KNOWN_GOOD_IMAGE="releaseguard:v1"

# Clean up containers left by an earlier demo run.
docker rm -f "$CANDIDATE_CONTAINER" "$RECOVERY_CONTAINER" 2>/dev/null || true

echo "=================================="
echo " ReleaseGuard: Docker Release Demo"
echo "=================================="

echo ""
echo "Starting candidate release..."

docker run -d \
  --name "$CANDIDATE_CONTAINER" \
  -e RELEASE_MODE=broken \
  -p "$CANDIDATE_PORT":3000 \
  "$KNOWN_GOOD_IMAGE"

echo ""
echo "Running release verification..."

if BASE_URL="http://localhost:$CANDIDATE_PORT" npm test; then
  echo "Candidate release PASSED verification."
else

  echo "Candidate release FAILED verification."
  echo "Starting recovery..."

  docker rm -f "$CANDIDATE_CONTAINER"

  echo "Starting known-good release..."

  docker run -d \
    --name "$RECOVERY_CONTAINER" \
    -e RELEASE_MODE=healthy \
    -p "$RECOVERY_PORT":3000 \
    "$KNOWN_GOOD_IMAGE"

  sleep 2

  echo "Verifying recovered release..."

  if BASE_URL="http://localhost:$RECOVERY_PORT" npm test; then
    echo "RECOVERY SUCCESSFUL: known-good release passed."
  else
    echo "RECOVERY FAILED: known-good release did not pass."
    exit 1
  fi

fi
