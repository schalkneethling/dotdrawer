import Foundation

/// Remembers which dotfiles the user chose to show in the drawer.
public struct SelectionStore {
    private static let key = "selectedDotfiles"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// The chosen files, in the order they were saved.
    public func load() -> [Dotfile] {
        guard let entries = defaults.array(forKey: Self.key) as? [[String: String]] else { return [] }
        return entries.compactMap { entry in
            guard let path = entry["path"], let group = entry["group"].flatMap(DotfileGroup.init(rawValue:)) else {
                return nil
            }
            return Dotfile(relativePath: path, group: group)
        }
    }

    public func save(_ dotfiles: [Dotfile]) {
        let entries = dotfiles.map { ["path": $0.relativePath, "group": $0.group.rawValue] }
        defaults.set(entries, forKey: Self.key)
    }
}
