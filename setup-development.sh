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

if ! command -v xdelta3 &> /dev/null; then
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt-get update
    sudo apt-get install -y xdelta3
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    brew install xdelta
  else
    echo "Warning: Unsupported OS for xdelta3 installation. Please install xdelta3 manually."
  fi
fi

npm install --global @limrun/cli
npx @limrun/cli ios create --xcode --reuse-if-exists --label name=sample-native-app-ios-cloud
npx @limrun/cli session start &
npx @limrun/cli ios sync ${SCRIPT_DIR} &
echo "Session started!"
