import Foundation

/// Finds which dotfiles exist in a home folder.
public struct DotfileScanner {
    private let home: URL
    private let fileManager: FileManager

    public init(home: URL, fileManager: FileManager = .default) {
        self.home = home
        self.fileManager = fileManager
    }

    /// Catalog entries that exist, followed by any other top-level dotfiles,
    /// ordered by group and then by path.
    public func scan() -> [Dotfile] {
        let known = DotfileCatalog.known.filter { isFile($0.relativePath) }
        let knownPaths = Set(known.map(\.relativePath))

        let topLevelNames = (try? fileManager.contentsOfDirectory(atPath: home.path)) ?? []
        let others = topLevelNames
            .filter { DotfileCatalog.isConfigurationName($0) && !knownPaths.contains($0) && isFile($0) }
            .map { Dotfile(relativePath: $0, group: .other) }

        let groupOrder = DotfileGroup.allCases
        return (known + others).sorted {
            let lhsGroup = groupOrder.firstIndex(of: $0.group)!
            let rhsGroup = groupOrder.firstIndex(of: $1.group)!
            return lhsGroup != rhsGroup ? lhsGroup < rhsGroup : $0.relativePath < $1.relativePath
        }
    }

    /// The absolute location of a dotfile in this home folder.
    public func url(for dotfile: Dotfile) -> URL {
        home.appending(path: dotfile.relativePath)
    }

    /// True for regular files, including symlinks to files, which is how
    /// many people manage dotfiles from a repository.
    public func isFile(_ relativePath: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: home.appending(path: relativePath).path, isDirectory: &isDirectory)
        return exists && !isDirectory.boolValue
    }
}
