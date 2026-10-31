#!/usr/bin/env bash
# Builds a universal release binary and wraps it in
# build/app.noindex/dotdrawer.app.
#
# Signs ad hoc by default, which is enough on the machine that built it. Set
# DOTDRAWER_SIGN_IDENTITY to a "Developer ID Application: …" identity to sign
# for distribution; release.sh does this before notarizing.
set -euo pipefail

cd "$(dirname "$0")/.."

identity="${DOTDRAWER_SIGN_IDENTITY:--}"

# Both architectures, so the app also runs on Intel Macs. The binary's
# minimum macOS still comes from the platforms setting in Package.swift.
arch_flags=(--arch arm64 --arch x86_64)
swift build -c release "${arch_flags[@]}"

# Spotlight skips folders ending in .noindex. Outside one, macOS registers
# the fresh bundle a few seconds after it appears, and launchers then list
# it next to the installed copy in /Applications.
app="build/app.noindex/dotdrawer.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$(swift build -c release "${arch_flags[@]}" --show-bin-path)/dotdrawer" "$app/Contents/MacOS/dotdrawer"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp Resources/MenuBarIcon.svg "$app/Contents/Resources/MenuBarIcon.svg"

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

if [[ "$identity" == "-" ]]; then
    # Ad-hoc signature: macOS accepts it on this machine, but other Macs
    # block it when it arrives as a download.
    codesign --force --sign - "$app"
else
    # Notarization requires the hardened runtime and a secure timestamp.
    codesign --force --options runtime --timestamp --sign "$identity" "$app"
fi

echo "Built $app"
