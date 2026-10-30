import AppKit
import DotdrawerCore
import SwiftUI

/// Shows the onboarding window, reusing it if it is already open.
@MainActor
final class OnboardingWindowController {
    private let homeAccess: HomeAccess
    private let store: SelectionStore
    private var window: NSWindow?

    init(homeAccess: HomeAccess, store: SelectionStore) {
        self.homeAccess = homeAccess
        self.store = store
    }

    func show() {
        // Build a fresh window unless one is on screen, so reopening after
        // the user closed it with the red button scans again.
        if window?.isVisible != true {
            let model = OnboardingModel(homeAccess: homeAccess, store: store) { [weak self] in
                self?.close()
            }
            let window = NSWindow(contentViewController: NSHostingController(rootView: OnboardingView(model: model)))
            window.title = "dotdrawer"
            window.styleMask = [.titled, .closable]
            // The controller owns the window; without this, closing it with
            // the red button would release it a second time.
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }

        // Accessory apps are never frontmost on their own, so bring the app
        // forward or the window opens behind whatever the user is using.
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }

    private func close() {
        window?.close()
        window = nil
    }
}
