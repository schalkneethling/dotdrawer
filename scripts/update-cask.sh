#!/usr/bin/env bash
# Points the Homebrew cask at a release: sets the version, the zip's
# checksum, and the minimum macOS in Casks/dotdrawer.rb in the tap
# repository, then commits and pushes. Run it after the release is published, because Homebrew downloads
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

# The cask's macOS requirement must match the app in this zip, or Homebrew
# would install it on Macs it can't run on. Homebrew names macOS versions,
# so map the major version of LSMinimumSystemVersion to that name.
min_macos=$(unzip -p "$zip" dotdrawer.app/Contents/Info.plist | plutil -extract LSMinimumSystemVersion raw -)
case "${min_macos%%.*}" in
    14) macos_name="sonoma" ;;
    15) macos_name="sequoia" ;;
    26) macos_name="tahoe" ;;
    27) macos_name="golden_gate" ;;
    *)
        echo "No Homebrew name for macOS $min_macos yet. Add it to update-cask.sh." >&2
        exit 1
        ;;
esac

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
    -e "s/^  depends_on macos: .*$/  depends_on macos: :$macos_name/" \
    "$tap/Casks/dotdrawer.rb"

# Running it twice for the same release changes nothing the second time.
if git -C "$tap" diff --quiet; then
    echo "The cask already points at $version."
    exit 0
fi

git -C "$tap" commit --quiet -am "Update dotdrawer to $version"
git -C "$tap" push --quiet
echo "Updated the cask to $version ($sha256)."
