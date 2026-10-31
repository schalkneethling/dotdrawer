#!/usr/bin/env bash
# Builds dotdrawer.app signed with a Developer ID, has Apple notarize it,
# staples the result, and zips it as build/release/dotdrawer-<version>.zip,
# ready to attach to a GitHub Release.
#
# Needs, once per Mac:
# - a "Developer ID Application" certificate in the login keychain
# - notarytool credentials saved in the keychain under the profile name in
#   DOTDRAWER_NOTARY_PROFILE (default: dotdrawer-notary)
# The README explains how to set up both.
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

app="build/app.noindex/dotdrawer.app"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")
mkdir -p build/release
zip="build/release/dotdrawer-$version.zip"

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

echo "Notarized $zip"
