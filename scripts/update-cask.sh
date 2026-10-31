#!/usr/bin/env bash
# Points the Homebrew cask at a release: sets the version and the zip's
# checksum in Casks/dotdrawer.rb in the tap repository, then commits and
# pushes. Run it after the release is published, because Homebrew downloads
# the zip from that release.
#
#   ./scripts/update-cask.sh <version>
#
# It reads the zip from build/release/<version>/, where release.sh puts it.
# Locally it clones the tap over SSH with your own GitHub access. The
# release workflow sets HOMEBREW_TAP_TOKEN to clone over HTTPS with a token
# instead. DOTDRAWER_TAP_URL overrides both, for example to test against a
# local copy of the tap.
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <version>" >&2
    exit 1
fi
version="$1"

zip="build/release/$version/dotdrawer-$version.zip"
if [[ ! -f "$zip" ]]; then
    echo "No $zip. Run ./scripts/release.sh for this version first." >&2
    exit 1
fi
sha256=$(shasum -a 256 "$zip" | cut -d ' ' -f 1)

if [[ -n "${DOTDRAWER_TAP_URL:-}" ]]; then
    tap_url="$DOTDRAWER_TAP_URL"
elif [[ -n "${HOMEBREW_TAP_TOKEN:-}" ]]; then
    tap_url="https://x-access-token:$HOMEBREW_TAP_TOKEN@github.com/schalkneethling/homebrew-dotdrawer.git"
else
    tap_url="git@github.com:schalkneethling/homebrew-dotdrawer.git"
fi

# Clone inside this checkout's build folder, not the system temp folder, so
# Git applies the same configuration as here. A Git config can pick the
# author and the commit signing key by folder, with includeIf.
mkdir -p build
tap=$(mktemp -d build/homebrew-tap.XXXXXX)
trap 'rm -rf "$tap"' EXIT
git clone --quiet "$tap_url" "$tap"

sed -i '' -E \
    -e "s/^  version \".*\"$/  version \"$version\"/" \
    -e "s/^  sha256 \".*\"$/  sha256 \"$sha256\"/" \
    "$tap/Casks/dotdrawer.rb"

# Running it twice for the same release changes nothing the second time.
if git -C "$tap" diff --quiet; then
    echo "The cask already points at $version."
    exit 0
fi

git -C "$tap" commit --quiet -am "Update dotdrawer to $version"
git -C "$tap" push --quiet
echo "Updated the cask to $version ($sha256)."
