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
bin_path="$(swift build -c release "${arch_flags[@]}" --show-bin-path)"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources" "$app/Contents/Frameworks"
cp "$bin_path/dotdrawer" "$app/Contents/MacOS/dotdrawer"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp Resources/MenuBarIcon.svg "$app/Contents/Resources/MenuBarIcon.svg"

# Sparkle, for in-app updates. ditto keeps the framework's symlinks intact.
# Its XPC services exist for sandboxed apps; dotdrawer isn't sandboxed, and
# Sparkle documents removing them in that case, which leaves fewer helpers
# to sign.
sparkle="$app/Contents/Frameworks/Sparkle.framework"
ditto "$bin_path/Sparkle.framework" "$sparkle"
rm -rf "$sparkle/XPCServices" "$sparkle/Versions/B/XPCServices"

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

# An ad-hoc signature is accepted on this machine, but other Macs block it
# when it arrives as a download. A Developer ID signature for notarization
# also needs the hardened runtime and a secure timestamp.
sign_flags=(--force --sign "$identity")
if [[ "$identity" != "-" ]]; then
    sign_flags+=(--options runtime --timestamp)
fi

# Sign from the inside out, in the order Sparkle documents: its helpers,
# then the framework, then the app, whose signature covers everything in it.
codesign "${sign_flags[@]}" "$sparkle/Versions/B/Autoupdate"
codesign "${sign_flags[@]}" "$sparkle/Versions/B/Updater.app"
codesign "${sign_flags[@]}" "$sparkle"
codesign "${sign_flags[@]}" "$app"

echo "Built $app"
