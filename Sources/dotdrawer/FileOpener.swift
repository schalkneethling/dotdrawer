import AppKit
import UniformTypeIdentifiers

/// Opens a file in the app macOS uses for it.
@MainActor
enum FileOpener {
    static func open(_ url: URL) {
        let workspace = NSWorkspace.shared
        // Many dotfiles have no extension (.zshrc, .gitconfig), so macOS may
        // have no app registered for them. Fall back to the default plain
        // text editor in that case.
        guard let app = workspace.urlForApplication(toOpen: url) ?? workspace.urlForApplication(toOpen: .plainText) else {
            NSSound.beep()
            return
        }
        workspace.open([url], withApplicationAt: app, configuration: NSWorkspace.OpenConfiguration())
    }
}
