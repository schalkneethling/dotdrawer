#!/usr/bin/env bash
# Points the Homebrew cask at a release: sets the version, the zip's
# checksum, and the minimum macOS in Casks/dotdrawer.rb in the tap
# repository, and opens a pull request that merges itself once the tap's
# required checks pass. The tap's main branch only accepts pull requests.
# Run it after the release is published, because Homebrew downloads the zip
# from that release.
#
#   ./scripts/update-cask.sh <version>
#
# It reads the zip from build/release/<version>/, where release.sh puts it.
# Locally it uses your own GitHub access: SSH for Git, and your gh login for
# the pull request. The release workflow sets HOMEBREW_TAP_TOKEN, which
# needs read and write access to the tap's contents and pull requests, and
# both use that instead. DOTDRAWER_TAP_URL points at another copy of the
# tap for testing; the script then pushes the branch there and stops before
# opening a pull request.
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

tap_repo="schalkneethling/homebrew-dotdrawer"
branch="update-dotdrawer-$version"

# An earlier run for this release may already have opened the pull request.
if git -C "$tap" ls-remote --exit-code --heads origin "$branch" > /dev/null; then
    echo "Branch $branch already exists in $tap_repo, so its pull request is already open or merged."
    exit 0
fi

git -C "$tap" switch --quiet -c "$branch"
git -C "$tap" commit --quiet -am "Update dotdrawer to $version"
git -C "$tap" push --quiet origin "$branch"

if [[ -n "${DOTDRAWER_TAP_URL:-}" ]]; then
    echo "Pushed $branch to $DOTDRAWER_TAP_URL. Not opening a pull request against a test copy."
    exit 0
fi

# gh opens the pull request through GitHub's API. In the workflow it uses
# the tap token; locally, your own gh login.
if [[ -n "${HOMEBREW_TAP_TOKEN:-}" ]]; then
    export GH_TOKEN="$HOMEBREW_TAP_TOKEN"
fi
pr_url=$(gh pr create --repo "$tap_repo" --base main --head "$branch" \
    --title "Update dotdrawer to $version" \
    --body "Points the cask at dotdrawer $version (sha256 \`$sha256\`, macOS :$macos_name or later). Opened by scripts/update-cask.sh in schalkneethling/dotdrawer.")

# Auto-merge needs it turned on in the tap's settings, which the tap's
# repository controls do. Without it, the pull request waits for a person.
if gh pr merge --repo "$tap_repo" --auto --squash "$branch"; then
    echo "Opened $pr_url. It merges once the tap's required checks pass."
else
    echo "Opened $pr_url, but couldn't turn on auto-merge for it. Merge it by hand." >&2
fi
