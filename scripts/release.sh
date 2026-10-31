#!/usr/bin/env bash
# Builds dotdrawer.app signed with a Developer ID, has Apple notarize it,
# staples the result, and writes two files to build/release/<version>/, ready
# to attach to a GitHub Release:
# - dotdrawer-<version>.zip, the app
# - appcast.xml, the feed Sparkle reads to find and verify the update
#
# Needs, once per Mac:
# - a "Developer ID Application" certificate in the keychain
# - notarytool credentials saved in the keychain under the profile name in
#   DOTDRAWER_NOTARY_PROFILE (default: dotdrawer-notary)
# - Sparkle's private EdDSA key in the login keychain, under the account
#   name "dotdrawer"
# The README explains how to set these up.
#
# The release workflow has no saved credentials, so it passes files instead:
# - DOTDRAWER_NOTARY_KEY_FILE, DOTDRAWER_NOTARY_KEY_ID and
#   DOTDRAWER_NOTARY_ISSUER: an App Store Connect API key for notarytool
# - DOTDRAWER_SPARKLE_KEY_FILE: Sparkle's exported private key
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -n "${DOTDRAWER_NOTARY_KEY_FILE:-}" ]]; then
    notary_auth=(--key "$DOTDRAWER_NOTARY_KEY_FILE" --key-id "$DOTDRAWER_NOTARY_KEY_ID" --issuer "$DOTDRAWER_NOTARY_ISSUER")
else
    notary_auth=(--keychain-profile "${DOTDRAWER_NOTARY_PROFILE:-dotdrawer-notary}")
fi

if [[ -n "${DOTDRAWER_SPARKLE_KEY_FILE:-}" ]]; then
    sparkle_auth=(--ed-key-file "$DOTDRAWER_SPARKLE_KEY_FILE")
else
    sparkle_auth=(--account dotdrawer)
fi

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
result=$(xcrun notarytool submit "$zip" "${notary_auth[@]}" --wait --output-format json)
status=$(plutil -extract status raw - <<< "$result")
if [[ "$status" != "Accepted" ]]; then
    id=$(plutil -extract id raw - <<< "$result")
    echo "Notarization finished with status \"$status\". Apple's log for it:" >&2
    xcrun notarytool log "$id" "${notary_auth[@]}" >&2 || true
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
.build/artifacts/sparkle/Sparkle/bin/generate_appcast \
    "${sparkle_auth[@]}" \
    --download-url-prefix "$repo/releases/download/v$version/" \
    --full-release-notes-url "$repo/releases" \
    "$out"

echo "Notarized $zip and wrote $out/appcast.xml"
