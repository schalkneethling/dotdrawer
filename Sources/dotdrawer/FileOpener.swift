import AppKit
import UniformTypeIdentifiers

/// Opens a file in the user's chosen editor, or in the app macOS uses for it.
@MainActor
enum FileOpener {
    static func open(_ url: URL, editorBundleIdentifier: String?) {
        let workspace = NSWorkspace.shared
        // A chosen editor that has since been uninstalled resolves to nil,
        // so the file still opens in its default app.
        let chosen = editorBundleIdentifier.flatMap(workspace.urlForApplication(withBundleIdentifier:))
        // Many dotfiles have no extension (.zshrc, .gitconfig), so macOS may
        // have no app registered for them. Fall back to the default plain
        // text editor in that case.
        guard let app = chosen ?? workspace.urlForApplication(toOpen: url) ?? workspace.urlForApplication(toOpen: .plainText) else {
            NSSound.beep()
            return
        }
        workspace.open([url], withApplicationAt: app, configuration: NSWorkspace.OpenConfiguration())
    }
}
