#!/usr/bin/env bash
set -e

if ! command -v apfel >/dev/null 2>&1; then
  echo "apfel is not installed. Install it with Homebrew:"
  echo "  brew tap Arthur-Ficial/tap"
  echo "  brew install Arthur-Ficial/tap/apfel"
  exit 1
fi

echo "Starting Apfel server on http://127.0.0.1:11434 ..."
apfel --serve --host 127.0.0.1 --port 11434 --cors --no-origin-check
