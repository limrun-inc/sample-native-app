#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
  set -a
  . "$ENV_FILE"
  set +a
fi

if [ -z "$LIM_API_KEY" ]; then
  echo "Error: LIM_API_KEY is not set"
  exit 1
fi

npm install --global @limrun/cli
echo "Ready for remote XCode & iOS simulators!"
