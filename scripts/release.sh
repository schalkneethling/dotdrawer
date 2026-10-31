#!/usr/bin/env bash
# Builds dotdrawer.app signed with a Developer ID, has Apple notarize it,
# staples the result, and writes two files to build/release/<version>/, ready
# to attach to a GitHub Release:
# - dotdrawer-<version>.zip, the app
# - appcast.xml, the feed Sparkle reads to find and verify the update
#
# Needs, once per Mac:
# - a "Developer ID Application" certificate in the login keychain
# - notarytool credentials saved in the keychain under the profile name in
#   DOTDRAWER_NOTARY_PROFILE (default: dotdrawer-notary)
# - Sparkle's private EdDSA key in the login keychain, under the account
#   name "dotdrawer"
# The README explains how to set these up.
set -euo pipefail

cd "$(dirname "$0")/.."

profile="${DOTDRAWER_NOTARY_PROFILE:-dotdrawer-notary}"

# Use DOTDRAWER_SIGN_IDENTITY when set; otherwise expect exactly one
# Developer ID Application identity in the keychain.
if [[ -z "${DOTDRAWER_SIGN_IDENTITY:-}" ]]; then
    identities=$(security find-identity -v -p codesigning | grep -o '"Developer ID Application: [^"]*"' | tr -d '"' || true)
    count=$(printf '%s' "$identities" | grep -c . || true)
    if [[ "$count" -ne 1 ]]; then
        echo "Found $count Developer ID Application identities. Set DOTDRAWER_SIGN_IDENTITY to the one to use." >&2
        exit 1
    fi
    export DOTDRAWER_SIGN_IDENTITY="$identities"
fi

./scripts/build-app.sh

# Sparkle installs an update only when it's signed with the private key that
# matches SUPublicEDKey. On a mismatch, generate_appcast just prints a
# warning and leaves the update unsigned, so compare the keys before
# spending a notarization round on a release nobody could install.
sparkle_bin=".build/artifacts/sparkle/Sparkle/bin"
expected_key=$(/usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' Resources/Info.plist)
keychain_key=$("$sparkle_bin/generate_keys" --account dotdrawer -p 2>/dev/null || true)
if [[ "$keychain_key" != "$expected_key" ]]; then
    echo "Sparkle's key in the keychain (account \"dotdrawer\") doesn't match SUPublicEDKey in Resources/Info.plist." >&2
    echo "  keychain:   ${keychain_key:-none}" >&2
    echo "  Info.plist: $expected_key" >&2
    echo "README › Releasing explains how to import the key." >&2
    exit 1
fi

app="build/app.noindex/dotdrawer.app"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")
# One folder per version, because generate_appcast adds an entry for every
# archive it finds in the folder.
out="build/release/$version"
rm -rf "$out"
mkdir -p "$out"
zip="$out/dotdrawer-$version.zip"

codesign --verify --strict --verbose=2 "$app"

# notarytool takes a zip, not a bare bundle. ditto keeps the bundle's
# symlinks and extended attributes intact, which plain zip does not.
rm -f "$zip"
ditto -c -k --keepParent "$app" "$zip"

# notarytool can exit successfully even when Apple rejects the upload, so
# check the reported status rather than the exit code.
result=$(xcrun notarytool submit "$zip" --keychain-profile "$profile" --wait --output-format json)
status=$(plutil -extract status raw - <<< "$result")
if [[ "$status" != "Accepted" ]]; then
    id=$(plutil -extract id raw - <<< "$result")
    echo "Notarization finished with status \"$status\". See why with:" >&2
    echo "  xcrun notarytool log $id --keychain-profile $profile" >&2
    exit 1
fi

# Attach the notarization ticket to the app, so Gatekeeper accepts it even
# offline, then zip again so the download carries the ticket.
xcrun stapler staple "$app"
spctl --assess --type execute --verbose=2 "$app"
rm -f "$zip"
ditto -c -k --keepParent "$app" "$zip"

# Sign the zip with Sparkle's private key and describe it in appcast.xml.
# The feed URL in Info.plist points at the latest release's appcast.xml, and
# the download URL here points at this version's zip on the same release.
repo="https://github.com/schalkneethling/dotdrawer"
"$sparkle_bin/generate_appcast" \
    --account dotdrawer \
    --download-url-prefix "$repo/releases/download/v$version/" \
    --full-release-notes-url "$repo/releases" \
    "$out"

# generate_appcast exits successfully even when it couldn't sign the update,
# so confirm the signature is there.
if ! grep -q 'sparkle:edSignature=' "$out/appcast.xml"; then
    echo "generate_appcast didn't sign the update in $out/appcast.xml. Don't publish this release." >&2
    exit 1
fi

echo "Notarized $zip and wrote $out/appcast.xml"
