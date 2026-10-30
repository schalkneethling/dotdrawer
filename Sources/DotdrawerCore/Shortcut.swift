import Foundation

/// A keyboard shortcut: one key plus modifier keys.
public struct Shortcut: Hashable, Codable, Sendable {
    public struct Modifiers: OptionSet, Hashable, Codable, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let control = Modifiers(rawValue: 1 << 0)
        public static let option = Modifiers(rawValue: 1 << 1)
        public static let shift = Modifiers(rawValue: 1 << 2)
        public static let command = Modifiers(rawValue: 1 << 3)
    }

    /// The key's position on the keyboard (a macOS virtual key code), which
    /// stays the same whatever keyboard layout is active.
    public let keyCode: UInt32
    public let modifiers: Modifiers
    /// What the key is labeled with, such as "D" or "Space", captured when
    /// the shortcut was recorded.
    public let keyLabel: String

    public init(keyCode: UInt32, modifiers: Modifiers, keyLabel: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.keyLabel = keyLabel
    }

    /// ⌃⌥⌘D: the D key (virtual key code 2) with Control, Option, and Command.
    public static let defaultOpenDrawer = Shortcut(keyCode: 2, modifiers: [.control, .option, .command], keyLabel: "D")

    /// The shortcut as macOS menus write it, with modifiers in the order
    /// ⌃⌥⇧⌘, such as "⌃⌥⌘D".
    public var displayString: String {
        let symbols: [(Modifiers, String)] = [(.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
        return symbols.filter { modifiers.contains($0.0) }.map(\.1).joined() + keyLabel
    }

    /// A global shortcut needs Control, Option, or Command. Without one,
    /// it would take over a key the user types, and Shift alone only turns
    /// letters into capitals.
    public var isAllowedAsGlobal: Bool {
        !modifiers.isDisjoint(with: [.control, .option, .command])
    }
}

/// Remembers the shortcut that opens the drawer.
public struct ShortcutStore {
    private static let key = "openDrawerShortcut"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// The saved shortcut, the default when none was ever saved, or nil
    /// when the user cleared it.
    public func load() -> Shortcut? {
        guard let data = defaults.data(forKey: Self.key) else { return .defaultOpenDrawer }
        // `try?` would flatten a saved "cleared" (nil) into the same nil as
        // a decoding failure, so catch failures explicitly.
        do {
            return try JSONDecoder().decode(Shortcut?.self, from: data)
        } catch {
            return .defaultOpenDrawer
        }
    }

    /// Saves a shortcut, or nil to turn the shortcut off. Clearing is saved
    /// too, so the default doesn't come back on the next launch.
    public func save(_ shortcut: Shortcut?) {
        defaults.set(try? JSONEncoder().encode(shortcut), forKey: Self.key)
    }
}
