/// An installed app that can open dotfiles.
public struct EditorApp: Hashable, Sendable {
    public let bundleIdentifier: String
    public let name: String
    public let path: String

    public init(bundleIdentifier: String, name: String, path: String) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.path = path
    }
}

/// Narrows the apps macOS reports for text files down to ones worth
/// offering as editors.
public enum EditorCatalog {
    /// Keeps apps installed in an application folder, drops browsers and
    /// duplicates, and sorts by name.
    ///
    /// macOS also reports copies hidden in caches, auto-update folders, and
    /// other apps' bundles (Instruments inside Xcode, for example), which
    /// would show up as confusing duplicates.
    public static func editors(
        from candidates: [EditorApp],
        browserIdentifiers: Set<String>,
        homePath: String
    ) -> [EditorApp] {
        let folders = ["/Applications/", "/System/Applications/", homePath + "/Applications/"]
        var seen = Set<String>()

        return candidates
            .filter { app in
                guard let folder = folders.first(where: app.path.hasPrefix) else { return false }
                // Exactly one bundle in the path below the folder, so apps
                // inside another app's bundle are skipped.
                let inside = app.path.dropFirst(folder.count)
                return inside.components(separatedBy: ".app/").count == 1 && inside.hasSuffix(".app")
            }
            .filter { !browserIdentifiers.contains($0.bundleIdentifier) }
            .filter { seen.insert($0.bundleIdentifier).inserted }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
