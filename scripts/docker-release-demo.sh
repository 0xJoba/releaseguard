#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/.."

CANDIDATE_CONTAINER="releaseguard-candidate"
RECOVERY_CONTAINER="releaseguard-recovery"
CANDIDATE_PORT=3003
RECOVERY_PORT=3004

CANDIDATE_IMAGE="releaseguard:v2"
KNOWN_GOOD_IMAGE="releaseguard:known-good"

echo "=================================="
echo " ReleaseGuard: Docker Rollback Demo"
echo "=================================="

# Clean up containers left by an earlier demo run.
docker rm -f "$CANDIDATE_CONTAINER" "$RECOVERY_CONTAINER" 2>/dev/null || true

echo ""
echo "Starting candidate image: $CANDIDATE_IMAGE"

docker run -d \
  --name "$CANDIDATE_CONTAINER" \
  -e RELEASE_MODE=broken \
  -p "$CANDIDATE_PORT":3000 \
  "$CANDIDATE_IMAGE"

echo ""
echo "Running release verification..."

if BASE_URL="http://localhost:$CANDIDATE_PORT" npm test; then
  echo "Candidate passed verification."
  docker rm -f "$CANDIDATE_CONTAINER"
else
  echo "Candidate FAILED verification."
  echo "Removing failed candidate..."

  docker rm -f "$CANDIDATE_CONTAINER"

  echo ""
  echo "Starting known-good image: $KNOWN_GOOD_IMAGE"

  docker run -d \
    --name "$RECOVERY_CONTAINER" \
    -p "$RECOVERY_PORT":3000 \
    "$KNOWN_GOOD_IMAGE"

  sleep 2

  echo ""
  echo "Verifying recovered release..."

  if BASE_URL="http://localhost:$RECOVERY_PORT" npm test; then
    echo "ROLLBACK SUCCESSFUL: known-good image passed verification."
  else
    echo "ROLLBACK FAILED: known-good image did not pass."
    exit 1
  fi
fi
