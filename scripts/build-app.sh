#!/usr/bin/env bash
# Builds a release binary and wraps it in build/dotdrawer.app.
set -euo pipefail

cd "$(dirname "$0")/.."

swift build -c release

app="build/dotdrawer.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$(swift build -c release --show-bin-path)/dotdrawer" "$app/Contents/MacOS/dotdrawer"
cp Resources/Info.plist "$app/Contents/Info.plist"

# Ad-hoc signature, so macOS accepts the bundle on this machine. It is not
# a Developer ID signature, so other Macs will warn before opening it.
codesign --force --sign - "$app"

echo "Built $app"
