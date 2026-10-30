#!/usr/bin/env bash
# Builds dotdrawer.app, installs it in /Applications, and launches it.
# Settings and home folder access carry over, because they belong to the
# bundle identifier, not to where the app lives.
set -euo pipefail

cd "$(dirname "$0")/.."

./scripts/build-app.sh

# Quit a running copy so the new one replaces it.
if pkill -x dotdrawer; then
    sleep 1
fi

target="/Applications/dotdrawer.app"
rm -rf "$target"
ditto build/app.noindex/dotdrawer.app "$target"

open "$target"
echo "Installed and launched $target"
