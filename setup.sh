#!/bin/bash
set -e

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

# Install limrun CLI from the typescript-cli branch
LIMRUN_CLI_DIR="/tmp/limrun-typescript-sdk"
if [ ! -d "$LIMRUN_CLI_DIR" ]; then
  git clone --branch typescript-cli --single-branch https://github.com/limrun-inc/typescript-sdk.git "$LIMRUN_CLI_DIR"
else
  git -C "$LIMRUN_CLI_DIR" pull
fi

cd "$LIMRUN_CLI_DIR/packages/cli"
npm install
npm run build
npm link
cd -
