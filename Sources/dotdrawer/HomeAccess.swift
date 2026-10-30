import AppKit

/// Asks the user once for access to their home folder and remembers the
/// answer as a security-scoped bookmark, so access survives relaunches.
/// Outside the App Sandbox the app could read the folder anyway, but the
/// same flow keeps working if the app is sandboxed later.
@MainActor
final class HomeAccess {
    enum RequestResult {
        case granted
        case cancelled
        case wrongFolder
    }

    private static let bookmarkKey = "homeFolderBookmark"
    private let defaults: UserDefaults

    /// The real home folder. FileManager's home folder points inside the
    /// app's container when sandboxed, so read it from the user database.
    static let realHome: URL = {
        let path = getpwuid(getuid()).map { String(cString: $0.pointee.pw_dir) } ?? NSHomeDirectory()
        return URL(fileURLWithPath: path, isDirectory: true)
    }()

    /// The folder the user must choose to grant access.
    let expectedHome = HomeAccess.realHome

    /// Set once the user has granted access, on this launch or an earlier one.
    private(set) var grantedHome: URL?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Restores access granted on an earlier launch. Returns false when the
    /// user has never granted access or the bookmark no longer resolves.
    func restore() -> Bool {
        guard let data = defaults.data(forKey: Self.bookmarkKey) else { return false }

        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, bookmarkDataIsStale: &isStale) else {
            defaults.removeObject(forKey: Self.bookmarkKey)
            return false
        }
        if isStale {
            saveBookmark(for: url)
        }
        startAccessing(url)
        return true
    }

    /// Shows an open panel pointed at the home folder and keeps the answer
    /// only when the user picks the home folder itself.
    func request() -> RequestResult {
        let panel = NSOpenPanel()
        panel.message = "Choose your home folder so dotdrawer can find your dotfiles."
        panel.prompt = "Grant Access"
        panel.directoryURL = expectedHome
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = true

        NSApp.activate()
        guard panel.runModal() == .OK, let url = panel.url else { return .cancelled }
        guard url.standardizedFileURL.path == expectedHome.standardizedFileURL.path else { return .wrongFolder }

        saveBookmark(for: url)
        startAccessing(url)
        return .granted
    }

    private func saveBookmark(for url: URL) {
        let data = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        defaults.set(data, forKey: Self.bookmarkKey)
    }

    private func startAccessing(_ url: URL) {
        grantedHome?.stopAccessingSecurityScopedResource()
        // The result is ignored because outside the sandbox the app can read
        // the folder whatever this returns.
        _ = url.startAccessingSecurityScopedResource()
        grantedHome = url
    }
}
