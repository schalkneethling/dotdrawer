import Foundation

/// Remembers which app opens every file, by bundle identifier. A bundle
/// identifier keeps working when the user moves or updates the app, which a
/// saved file path would not. No saved app means each file opens in the app
/// macOS uses for its file type.
public struct EditorPreference {
    private static let key = "editorBundleIdentifier"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> String? {
        defaults.string(forKey: Self.key)
    }

    public func save(_ bundleIdentifier: String?) {
        if let bundleIdentifier {
            defaults.set(bundleIdentifier, forKey: Self.key)
        } else {
            defaults.removeObject(forKey: Self.key)
        }
    }
}
