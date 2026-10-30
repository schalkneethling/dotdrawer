# dotdrawer

A macOS menu bar app that gives quick access to your dotfiles and global agent configs, such as `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`.

Click the menu bar icon to open a drawer listing the files you chose. Select one with the mouse or keyboard, and it opens in your default editor.

## How it works

- **Onboarding:** on first launch, you choose your home folder in a macOS open panel. dotdrawer stores that permission as a security-scoped bookmark, so it doesn't ask again on later launches.
- **Scan:** dotdrawer looks for well-known files, such as agent configs, shell startup files, and tool configs, plus any other dotfile at the top level of your home folder. History files and caches are skipped.
- **Choose:** you tick the files you want in the drawer. Agent configs start ticked. Reopen the list any time with **Choose Files…** in the menu.
- **Open:** selecting a file opens it in the app macOS uses for that file type. For files without an extension, such as `.zshrc`, it falls back to your default plain-text editor.

## Status

Early development. The app is not sandboxed, and it is signed ad hoc, so it runs on the machine that built it without warnings, while other Macs will warn before opening it.

## Build the app

```bash
./scripts/build-app.sh
open build/dotdrawer.app
```

The script builds a release binary and wraps it in `build/dotdrawer.app`, which carries the bundle identifier `com.schalkneethling.dotdrawer`.

### Can't see the menu bar icon?

On a Mac with a notch, a full menu bar can push new icons behind the notch, and some apps draw overlays on top of the menu bar. Open dotdrawer again (from Finder or Spotlight) to bring up its window. To move the icon, hold ⌘ and drag it to a visible spot. dotdrawer remembers that position.

## Development

```bash
swift build
swift test
swift run
```

The logic that doesn't need a UI (the catalog, scanner, and saved selection) lives in the `DotdrawerCore` library, which the tests cover. The menu bar app is the `dotdrawer` executable.
