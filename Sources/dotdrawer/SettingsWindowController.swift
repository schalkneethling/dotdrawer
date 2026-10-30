import AppKit
import DotdrawerCore
import SwiftUI

/// Shows the setup and Settings window, reusing it if it is already open.
@MainActor
final class SettingsWindowController {
    private let homeAccess: HomeAccess
    private let store: SelectionStore
    private let editorPreference: EditorPreference
    private let drawerShortcut: DrawerShortcut
    private var window: NSWindow?
    private var model: SettingsModel?

    init(homeAccess: HomeAccess, store: SelectionStore, editorPreference: EditorPreference, drawerShortcut: DrawerShortcut) {
        self.homeAccess = homeAccess
        self.store = store
        self.editorPreference = editorPreference
        self.drawerShortcut = drawerShortcut
    }

    func show() {
        // Build a fresh window unless one is on screen, so reopening after
        // the user closed it with the red button scans again.
        if window?.isVisible != true {
            let model = SettingsModel(
                homeAccess: homeAccess,
                store: store,
                editorPreference: editorPreference,
                drawerShortcut: drawerShortcut
            ) { [weak self] in
                self?.close()
            }
            let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(model: model)))
            window.title = "dotdrawer"
            window.styleMask = [.titled, .closable]
            // The controller owns the window; without this, closing it with
            // the red button would release it a second time.
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
            self.model = model
        }

        // Accessory apps are never frontmost on their own, so ask to come
        // forward. macOS can refuse that request when the user is busy in
        // another app (on first launch, for example), so also put the window
        // on top without taking focus, or it would open hidden behind them.
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
    }

    /// Keeps an open window's picker in step with a choice made in the menu.
    func editorDidChange(to bundleIdentifier: String?) {
        guard window?.isVisible == true else { return }
        model?.showEditor(bundleIdentifier)
    }

    private func close() {
        window?.close()
        window = nil
        model = nil
    }
}
