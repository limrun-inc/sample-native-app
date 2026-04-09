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

npm -C .agents/skills/limrun-skill install
npx tsx .agents/skills/limrun-skill/limrun-daemon.ts &
pid=$!

echo "Xcode sandbox running on PID: $pid"
echo "To stop the sandbox, run: kill $pid"