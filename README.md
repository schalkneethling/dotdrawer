# dotdrawer

A macOS menu bar app that gives quick access to your dotfiles and global agent configs, such as `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`.

Click the menu bar icon to open a drawer listing the files you chose. Select one with the mouse or keyboard, and it opens in your default editor.

## Planned behavior

- **Onboarding:** you grant file access, and the app scans for common dotfiles. You then pick which ones appear in the drawer.
- **Scope:** starts with agent configs and grows to cover other dotfiles.
- **Built with:** native Swift and AppKit, so the menu bar icon and file access use macOS APIs directly.

## Status

Early setup. The package builds and the test target runs, but the app does not do anything yet.

## Development

```bash
swift build
swift test
```
