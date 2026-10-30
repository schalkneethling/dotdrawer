/// The sections the drawer and Settings window group files into, in display order.
public enum DotfileGroup: String, CaseIterable, Sendable {
    case agents = "Agent configs"
    case shell = "Shell"
    case tools = "Tools"
    case other = "Other dotfiles"
}

/// A file in the user's home folder that dotdrawer can show.
public struct Dotfile: Hashable, Sendable {
    /// Path relative to the home folder, such as `.claude/CLAUDE.md`.
    public let relativePath: String
    public let group: DotfileGroup

    public init(relativePath: String, group: DotfileGroup) {
        self.relativePath = relativePath
        self.group = group
    }

    /// The path as people write it, such as `~/.claude/CLAUDE.md`.
    public var displayPath: String { "~/" + relativePath }
}
