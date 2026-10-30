import AppKit
import DotdrawerCore
import UniformTypeIdentifiers

/// Asks macOS which installed apps can open dotfiles.
@MainActor
enum InstalledEditors {
    static func list() -> [EditorApp] {
        let workspace = NSWorkspace.shared
        let candidates = (workspace.urlsForApplications(toOpen: .plainText) + workspace.urlsForApplications(toOpen: .sourceCode))
            .compactMap(editorApp(at:))

        // Browsers register for text files too, but only display them.
        // Any app that opens web links counts as a browser.
        let browsers = workspace.urlsForApplications(toOpen: URL(string: "https://example.com")!)
            .compactMap { Bundle(url: $0)?.bundleIdentifier }

        return EditorCatalog.editors(from: candidates, browserIdentifiers: Set(browsers), homePath: HomeAccess.realHome.path)
    }

    /// The editors to offer and which one is current, given the saved
    /// choice. An editor picked with Other… isn't in the generated list, so
    /// it is added back. One that has been uninstalled counts as no choice,
    /// which matches what opening a file does.
    static func choices(saved: String?) -> (editors: [EditorApp], current: String?) {
        var editors = list()
        guard let saved else { return (editors, nil) }

        if !editors.contains(where: { $0.bundleIdentifier == saved }) {
            guard let editor = editor(withBundleIdentifier: saved) else { return (editors, nil) }
            editors.append(editor)
        }
        return (editors, saved)
    }

    /// Lets the user pick any app, for editors the list doesn't include.
    static func pickOther() -> EditorApp? {
        let panel = NSOpenPanel()
        panel.message = "Choose the app dotdrawer should open files with."
        panel.prompt = "Choose"
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false

        NSApp.activate()
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return editorApp(at: url)
    }

    /// The app's icon at menu size.
    static func icon(for editor: EditorApp) -> NSImage {
        let icon = NSWorkspace.shared.icon(forFile: editor.path)
        icon.size = NSSize(width: 16, height: 16)
        return icon
    }

    /// Finds an installed app by bundle identifier, or nil when it is gone.
    static func editor(withBundleIdentifier bundleIdentifier: String) -> EditorApp? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier).flatMap(editorApp(at:))
    }

    /// Describes the app at a URL, or nil when it has no bundle identifier.
    static func editorApp(at url: URL) -> EditorApp? {
        guard let bundleIdentifier = Bundle(url: url)?.bundleIdentifier else { return nil }
        let name = FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
        return EditorApp(bundleIdentifier: bundleIdentifier, name: name, path: url.path)
    }
}
