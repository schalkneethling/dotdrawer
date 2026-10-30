import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    // Placeholder list until onboarding lets the user choose their own files.
    private let placeholderPaths = [
        "~/.claude/CLAUDE.md",
        "~/.codex/AGENTS.md",
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: "dotdrawer")
        item.menu = makeMenu()
        statusItem = item
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        // Only list files that exist, so a missing file never shows up as a broken entry.
        for path in placeholderPaths {
            let url = URL(fileURLWithPath: NSString(string: path).expandingTildeInPath)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }

            let entry = NSMenuItem(title: path, action: #selector(openFile(_:)), keyEquivalent: "")
            entry.target = self
            entry.representedObject = url
            menu.addItem(entry)
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit dotdrawer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    @objc private func openFile(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }
}
