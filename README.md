# dotdrawer

A macOS menu bar app that gives quick access to your dotfiles and global agent configs, such as `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`.

Click the menu bar icon to open a drawer listing the files you chose. Select one with the mouse or keyboard, and it opens in your default editor.

## How it works

- **Onboarding:** on first launch, you choose your home folder in a macOS open panel. dotdrawer stores that permission as a security-scoped bookmark, so it doesn't ask again on later launches.
- **Scan:** dotdrawer looks for well-known files, such as agent configs, shell startup files, and tool configs, plus any other dotfile at the top level of your home folder. History files and caches are skipped.
- **Choose:** you tick the files you want in the drawer. Agent configs start ticked. Changes save as you make them, so closing the window any way keeps them. Reopen the list any time with **Choose Files…** in the menu.
- **Open:** selecting a file opens it in the editor you chose with **Set Default Editor** in the menu, or under **Open files with** in the Choose Files window. Both list installed apps that edit text, and **Other…** lets you pick any app. If you keep the default, each file opens in the app macOS uses for its type, and files without an extension, such as `.zshrc`, open in your default plain-text editor.

## Status

Early development. The app is not sandboxed, and it is signed ad hoc, so it runs on the machine that built it without warnings, while other Macs will warn before opening it.

## Install

```bash
./scripts/install-app.sh
```

The script builds the app, replaces `/Applications/dotdrawer.app`, and launches it, so it shows up in Finder, Spotlight, and other launchers. Your settings and home folder access carry over between installs.

To build without installing, run `./scripts/build-app.sh`, which leaves the app in `build/app.noindex/dotdrawer.app`. The `.noindex` folder keeps Spotlight, and so your launcher, from listing that copy next to the installed one. The app carries the bundle identifier `com.schalkneethling.dotdrawer`.

### Can't see the menu bar icon?

On a Mac with a notch, a full menu bar can push new icons behind the notch, and some apps draw overlays on top of the menu bar. Open dotdrawer again (from Finder, Spotlight, or your launcher) to bring up its window. To move the icon, hold ⌘ and drag it to a visible spot. dotdrawer remembers that position.

## Development

```bash
swift build
swift test
swift run
```

The logic that doesn't need a UI (the catalog, scanner, and saved selection) lives in the `DotdrawerCore` library, which the tests cover. The menu bar app is the `dotdrawer` executable.
