#!/usr/bin/env bash
# Renders scripts/og-image.html to site/og-image.png, the 1200×630 preview
# image that social media shows for links to the website.
#
# Uses Google Chrome's headless mode. Set CHROME to another Chrome or
# Chromium binary to use that instead.
set -euo pipefail

cd "$(dirname "$0")/.."

chrome="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
if [[ ! -x "$chrome" ]]; then
  echo "Chrome not found at $chrome. Set CHROME to a Chrome or Chromium binary." >&2
  exit 1
fi

# The virtual time budget lets the page load its fonts from Google Fonts
# before the screenshot, so the image doesn't show fallback fonts.
"$chrome" \
  --headless \
  --hide-scrollbars \
  --force-device-scale-factor=1 \
  --window-size=1200,630 \
  --virtual-time-budget=5000 \
  --screenshot="$PWD/site/og-image.png" \
  "file://$PWD/scripts/og-image.html"
