#!/usr/bin/env bash
# Builds a release binary and wraps it in build/app.noindex/dotdrawer.app.
set -euo pipefail

cd "$(dirname "$0")/.."

swift build -c release

# Spotlight skips folders ending in .noindex. Outside one, macOS registers
# the fresh bundle a few seconds after it appears, and launchers then list
# it next to the installed copy in /Applications.
app="build/app.noindex/dotdrawer.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$(swift build -c release --show-bin-path)/dotdrawer" "$app/Contents/MacOS/dotdrawer"
cp Resources/Info.plist "$app/Contents/Info.plist"

# Compile the Icon Composer file into Assets.car and AppIcon.icns. The
# deployment target matches LSMinimumSystemVersion in Info.plist. actool
# reports progress as XML on stdout, so keep that quiet and check the result.
xcrun actool \
    --compile "$app/Contents/Resources" \
    --platform macosx \
    --minimum-deployment-target 14.0 \
    --app-icon AppIcon \
    --output-partial-info-plist "build/app.noindex/icon-info.plist" \
    Resources/AppIcon.icon > /dev/null
if [[ ! -f "$app/Contents/Resources/Assets.car" ]]; then
    echo "actool did not produce Assets.car from Resources/AppIcon.icon" >&2
    exit 1
fi

# Ad-hoc signature, so macOS accepts the bundle on this machine. It is not
# a Developer ID signature, so other Macs will warn before opening it.
codesign --force --sign - "$app"

echo "Built $app"
