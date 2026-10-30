import AppKit
import DotdrawerCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private let homeAccess = HomeAccess()
    private let store = SelectionStore()
    private lazy var onboarding = OnboardingWindowController(homeAccess: homeAccess, store: store)

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        // Rebuilt each time it opens, so it always reflects the saved
        // selection and which files currently exist.
        menu.delegate = self

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: "dotdrawer")
        item.menu = menu
        // Remembers where the user ⌘-drags the icon. On a crowded menu bar,
        // macOS can place a new icon behind the notch.
        item.autosaveName = "dotdrawer"
        statusItem = item

        if !homeAccess.restore() {
            onboarding.show()
        }
    }

    /// Opening the app again while it runs shows the setup or Choose Files
    /// window, so the app stays reachable even when its icon is hidden.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        onboarding.show()
        return false
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        if let home = homeAccess.grantedHome {
            addFileItems(to: menu, home: home)
            menu.addItem(NSMenuItem(title: "Choose Files…", action: #selector(showOnboarding), keyEquivalent: ","))
        } else {
            menu.addItem(NSMenuItem(title: "Set Up dotdrawer…", action: #selector(showOnboarding), keyEquivalent: ""))
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit dotdrawer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        for item in menu.items where item.action == #selector(showOnboarding) {
            item.target = self
        }
    }

    private func addFileItems(to menu: NSMenu, home: URL) {
        let scanner = DotfileScanner(home: home)
        let selection = store.load()

        guard !selection.isEmpty else {
            let empty = NSMenuItem(title: "No files chosen", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
            menu.addItem(.separator())
            return
        }

        // Keep each group together, with a separator between groups.
        for group in DotfileGroup.allCases {
            let files = selection.filter { $0.group == group }
            guard !files.isEmpty else { continue }

            for file in files {
                let entry = NSMenuItem(title: file.displayPath, action: #selector(openFile(_:)), keyEquivalent: "")
                entry.target = self
                entry.representedObject = scanner.url(for: file)
                // A chosen file can be deleted later; show it disabled instead
                // of silently dropping it, so the user knows why it is gone.
                if !scanner.isFile(file.relativePath) {
                    entry.title += " (missing)"
                    entry.action = nil
                    entry.isEnabled = false
                }
                menu.addItem(entry)
            }
            menu.addItem(.separator())
        }
    }

    @objc private func openFile(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        FileOpener.open(url)
    }

    @objc private func showOnboarding() {
        onboarding.show()
    }
}
