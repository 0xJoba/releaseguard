
#!/usr/bin/env bash

echo "Starting release verification..."

npm test
TEST_EXIT_CODE=$?

if [ "$TEST_EXIT_CODE" -eq 0 ]; then
  echo "Release verification passed. Safe to proceed."
  exit 0
else
  echo "Release verification failed. Block this release."
  exit 1
fi

