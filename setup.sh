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

npm -C xcode-sandbox install
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
node xcode-sandbox/index.ts "${SCRIPT_DIR}" &
pid=$!

echo "Xcode sandbox running on PID: $pid"
echo "To stop the sandbox, run: kill $pid"