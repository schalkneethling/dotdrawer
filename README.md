# dotdrawer

A macOS menu bar app that gives quick access to your dotfiles and global agent configs, such as `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`.

Click the menu bar icon, or press ⌃⌥⌘D from any app, to open a drawer listing the files you chose. Select one with the mouse or keyboard, and it opens in your default editor.

[![dotdrawer opening ~/.claude/CLAUDE.md in Zed: ⌃⌥⌘D opens the drawer, then Return opens the selected file](docs/media/demo.gif)](docs/media/demo.mp4)

## How it works

- **Onboarding:** on first launch, you choose your home folder in a macOS open panel. dotdrawer stores that permission as a security-scoped bookmark, so it doesn't ask again on later launches.
- **Scan:** dotdrawer looks for well-known files, such as agent configs, shell startup files, and tool configs, plus any other dotfile at the top level of your home folder. History files and caches are skipped.
- **Choose:** you tick the files you want in the drawer. Agent configs start ticked. Changes save as you make them, so closing the window any way keeps them. Reopen the list any time with **Settings…** (⌘,) in the menu.
- **Open:** selecting a file opens it in the editor you chose with **Set Default Editor** in the menu, or under **Open files with** in Settings. Both list installed apps that edit text, and **Other…** lets you pick any app. If you keep the default, each file opens in the app macOS uses for its type, and files without an extension, such as `.zshrc`, open in your default plain-text editor.
- **Shortcut:** ⌃⌥⌘D opens the drawer from any app, even when the menu bar icon is hidden. Change or clear it under **Open drawer with** in Settings. If another app claims the same shortcut exclusively, Settings says so and keeps your previous shortcut. macOS can't detect clashes with apps that don't claim their shortcut exclusively, so if the drawer doesn't open, try a different combination.
- **Launch at login:** turn on **Launch dotdrawer at login** in Settings. If you later turn dotdrawer off under System Settings › General › Login Items, Settings shows a button that takes you there to approve it again.

## Status

Early development. The app is not sandboxed. It runs on macOS 14 or later, on Apple silicon and Intel Macs.

## Install

### From a release

Download `dotdrawer-<version>.zip` from [Releases](https://github.com/schalkneethling/dotdrawer/releases), unzip it, and move `dotdrawer.app` to `/Applications`. Releases are signed with a Developer ID and notarized by Apple, so macOS opens them without warnings.

### From source

You need Xcode 27 or later, because the package uses Swift 6.4 and the icon is compiled with Xcode's `actool`.

```bash
./scripts/install-app.sh
```

The script builds the app, replaces `/Applications/dotdrawer.app`, and launches it, so it shows up in Finder, Spotlight, and other launchers. Your settings and home folder access carry over between installs.

To build without installing, run `./scripts/build-app.sh`, which leaves the app in `build/app.noindex/dotdrawer.app`. The `.noindex` folder keeps Spotlight, and so your launcher, from listing that copy next to the installed one. The app carries the bundle identifier `com.schalkneethling.dotdrawer`. A build from source is signed ad hoc, which macOS accepts on the Mac that built it, but blocks when the app is copied to another Mac as a download.

### Can't see the menu bar icon?

On a Mac with a notch, a full menu bar can push new icons behind the notch, and some apps draw overlays on top of the menu bar. Press ⌃⌥⌘D to open the drawer anyway, or open dotdrawer again (from Finder, Spotlight, or your launcher) to bring up Settings. To move the icon, hold ⌘ and drag it to a visible spot. dotdrawer remembers that position.

## Development

```bash
swift build
swift test
swift run
```

The app icon is `Resources/AppIcon.icon`. Open it in Icon Composer (Xcode › Open Developer Tool › Icon Composer) to edit it. `build-app.sh` compiles it with `actool` into the bundle's `Assets.car` and an `AppIcon.icns` fallback. The menu bar icon is `Resources/MenuBarIcon.svg`, a single-color SVG on a square canvas with a small margin built in, shown at 18pt. dotdrawer shows it as a template image, so only its shape matters: macOS colors it to match the menu bar.

The logic that doesn't need a UI (the dotfile catalog and scanner, the editor list filter, the shortcut model, and the saved settings) lives in the `DotdrawerCore` library, which the tests cover. The menu bar app is the `dotdrawer` executable.

## Releasing

`./scripts/release.sh` builds the app, signs it with a Developer ID, has Apple notarize it, staples the notarization ticket to the app, and writes `build/release/dotdrawer-<version>.zip`. The version comes from `CFBundleShortVersionString` in `Resources/Info.plist`, so bump it, and `CFBundleVersion`, before each release.

The script needs two things on the Mac that runs it, both set up once:

1. **A Developer ID Application certificate.** Only the Account Holder of an Apple Developer Program membership can create one. In Xcode, open Settings › Accounts, select the team, choose Manage Certificates, then click + and pick Developer ID Application. If the keychain holds more than one, set `DOTDRAWER_SIGN_IDENTITY` to the full name of the one to use.
2. **Saved notarization credentials.** Create an app-specific password at [account.apple.com](https://account.apple.com) under Sign-In and Security, then store it in the keychain. `notarytool` prompts for the password:

   ```bash
   xcrun notarytool store-credentials dotdrawer-notary --apple-id <your Apple Account email> --team-id <your team ID>
   ```

   To use a different profile name, set `DOTDRAWER_NOTARY_PROFILE`.

Then create the release on GitHub with the zip attached:

```bash
gh release create v<version> build/release/dotdrawer-<version>.zip --generate-notes
```

## License

[MIT](LICENSE)
