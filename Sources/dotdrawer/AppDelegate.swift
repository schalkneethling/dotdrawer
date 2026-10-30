import AppKit
import DotdrawerCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private let homeAccess = HomeAccess()
    private let store = SelectionStore()
    private let editorPreference = EditorPreference()
    private lazy var drawerShortcut = DrawerShortcut { [weak self] in self?.openDrawer() }
    private lazy var settings = SettingsWindowController(
        homeAccess: homeAccess,
        store: store,
        editorPreference: editorPreference,
        drawerShortcut: drawerShortcut
    )

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

        drawerShortcut.activate()

        if !homeAccess.restore() {
            settings.show()
        }
    }

    /// Opens the drawer as if the user clicked the icon. This works even
    /// when the icon is hidden behind the notch or another app's overlay,
    /// because the menu drops down below the menu bar.
    private func openDrawer() {
        statusItem?.button?.performClick(nil)
    }

    /// Opening the app again while it runs shows the setup or Settings
    /// window, so the app stays reachable even when its icon is hidden.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        settings.show()
        return false
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        if let home = homeAccess.grantedHome {
            addFileItems(to: menu, home: home)
            menu.addItem(NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ","))
            menu.addItem(makeEditorMenuItem())
        } else {
            menu.addItem(NSMenuItem(title: "Set Up dotdrawer…", action: #selector(showSettings), keyEquivalent: ""))
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit dotdrawer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        for item in menu.items where item.action == #selector(showSettings) {
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

    /// A submenu listing the editors, with a checkmark on the current one.
    private func makeEditorMenuItem() -> NSMenuItem {
        let choices = InstalledEditors.choices(saved: editorPreference.load())
        let submenu = NSMenu()

        let defaultApps = NSMenuItem(title: "Default App for Each File", action: #selector(setEditor(_:)), keyEquivalent: "")
        defaultApps.state = choices.current == nil ? .on : .off
        submenu.addItem(defaultApps)
        submenu.addItem(.separator())

        for editor in choices.editors {
            let item = NSMenuItem(title: editor.name, action: #selector(setEditor(_:)), keyEquivalent: "")
            item.representedObject = editor.bundleIdentifier
            item.image = InstalledEditors.icon(for: editor)
            item.state = editor.bundleIdentifier == choices.current ? .on : .off
            submenu.addItem(item)
        }

        submenu.addItem(.separator())
        submenu.addItem(NSMenuItem(title: "Other…", action: #selector(setOtherEditor), keyEquivalent: ""))
        for item in submenu.items {
            item.target = self
        }

        let parent = NSMenuItem(title: "Set Default Editor", action: nil, keyEquivalent: "")
        parent.submenu = submenu
        return parent
    }

    @objc private func openFile(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        FileOpener.open(url, editorBundleIdentifier: editorPreference.load())
    }

    /// Saves the editor a submenu item stands for; nil means default apps.
    @objc private func setEditor(_ sender: NSMenuItem) {
        saveEditor(sender.representedObject as? String)
    }

    @objc private func setOtherEditor() {
        guard let editor = InstalledEditors.pickOther() else { return }
        saveEditor(editor.bundleIdentifier)
    }

    private func saveEditor(_ bundleIdentifier: String?) {
        editorPreference.save(bundleIdentifier)
        settings.editorDidChange(to: bundleIdentifier)
    }

    @objc private func showSettings() {
        settings.show()
    }
}
