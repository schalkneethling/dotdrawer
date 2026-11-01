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

tap_repo="schalkneethling/homebrew-dotdrawer"
branch="update-dotdrawer-$version"

update_cask() {
    sed -i '' -E \
        -e "s/^  version \".*\"$/  version \"$version\"/" \
        -e "s/^  sha256 \".*\"$/  sha256 \"$sha256\"/" \
        -e "s/^  depends_on macos: .*$/  depends_on macos: :$macos_name/" \
        "$tap/Casks/dotdrawer.rb"
}

# Running it again after the update merged changes nothing.
update_cask
if git -C "$tap" diff --quiet; then
    echo "The cask already points at $version."
    exit 0
fi

# gh talks to GitHub's API for the pull request. In the workflow it uses
# the tap token; locally, your own gh login. A test copy of the tap gets no
# pull request, so it needs neither.
testing="${DOTDRAWER_TAP_URL:+yes}"
if [[ -z "$testing" ]]; then
    if [[ -n "${HOMEBREW_TAP_TOKEN:-}" ]]; then
        export GH_TOKEN="$HOMEBREW_TAP_TOKEN"
    fi
    open_pr=$(gh pr list --repo "$tap_repo" --head "$branch" --state open --json url --jq '.[0].url // empty')
    if [[ -n "$open_pr" ]]; then
        echo "A pull request for $version is already open: $open_pr"
        exit 0
    fi
fi

# A branch without an open pull request means an earlier run pushed it and
# then failed to open the pull request. Continue from that branch, because
# a new branch from main with the same name would be rejected as a push.
if git -C "$tap" ls-remote --exit-code --heads origin "$branch" > /dev/null; then
    git -C "$tap" checkout --quiet -- Casks/dotdrawer.rb
    git -C "$tap" fetch --quiet origin "$branch"
    git -C "$tap" switch --quiet -c "$branch" FETCH_HEAD
    update_cask
else
    git -C "$tap" switch --quiet -c "$branch"
fi
if ! git -C "$tap" diff --quiet; then
    git -C "$tap" commit --quiet -am "Update dotdrawer to $version"
fi
git -C "$tap" push --quiet origin "$branch"

# The test URL can contain credentials, so it stays out of the output.
if [[ -n "$testing" ]]; then
    echo "Pushed $branch to the test copy of the tap. Not opening a pull request there."
    exit 0
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
