import DotdrawerCore

/// The shortcut that opens the drawer: what is saved, what is registered
/// with macOS, and why registering failed, if it did.
@MainActor
final class DrawerShortcut {
    private let store: ShortcutStore
    private let hotKey: GlobalHotKey

    /// The shortcut in effect, or nil when the user turned it off.
    private(set) var current: Shortcut?
    /// Set when macOS refused the shortcut, so Settings can say why.
    private(set) var problem: String?

    init(store: ShortcutStore = ShortcutStore(), onPress: @escaping () -> Void) {
        self.store = store
        hotKey = GlobalHotKey(onPress: onPress)
        current = store.load()
    }

    /// Registers the saved shortcut, at launch.
    func activate() {
        register(current)
    }

    /// Saves and registers a new shortcut, or nil to turn it off. A shortcut
    /// another app already uses is not saved, so the old one stays active.
    func change(to shortcut: Shortcut?) {
        let previous = current
        if register(shortcut) {
            current = shortcut
            store.save(shortcut)
        } else {
            register(previous, keepingProblem: true)
        }
    }

    /// Stops the shortcut while a new one is recorded, so pressing the
    /// current combination records it instead of opening the drawer.
    func suspend() {
        hotKey.unregister()
    }

    func resume() {
        register(current)
    }

    @discardableResult
    private func register(_ shortcut: Shortcut?, keepingProblem: Bool = false) -> Bool {
        do {
            try hotKey.register(shortcut)
            if !keepingProblem { problem = nil }
            return true
        } catch .takenByAnotherApp {
            problem = "Another app already uses \(shortcut?.displayString ?? "that shortcut"). Choose a different one."
            return false
        } catch {
            problem = "macOS couldn't register \(shortcut?.displayString ?? "the shortcut")."
            return false
        }
    }
}
