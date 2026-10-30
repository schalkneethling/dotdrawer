/// Well-known dotfiles worth looking for, including ones nested in folders
/// that a scan of the home folder's top level would not find.
public enum DotfileCatalog {
    public static let known: [Dotfile] = [
        Dotfile(relativePath: ".claude/CLAUDE.md", group: .agents),
        Dotfile(relativePath: ".claude/settings.json", group: .agents),
        Dotfile(relativePath: ".codex/AGENTS.md", group: .agents),
        Dotfile(relativePath: ".codex/config.toml", group: .agents),
        Dotfile(relativePath: ".gemini/GEMINI.md", group: .agents),
        Dotfile(relativePath: ".gemini/settings.json", group: .agents),

        Dotfile(relativePath: ".zshrc", group: .shell),
        Dotfile(relativePath: ".zprofile", group: .shell),
        Dotfile(relativePath: ".zshenv", group: .shell),
        Dotfile(relativePath: ".bashrc", group: .shell),
        Dotfile(relativePath: ".bash_profile", group: .shell),
        Dotfile(relativePath: ".profile", group: .shell),

        Dotfile(relativePath: ".gitconfig", group: .tools),
        Dotfile(relativePath: ".ssh/config", group: .tools),
        Dotfile(relativePath: ".npmrc", group: .tools),
        Dotfile(relativePath: ".vimrc", group: .tools),
        Dotfile(relativePath: ".config/nvim/init.lua", group: .tools),
        Dotfile(relativePath: ".tmux.conf", group: .tools),
        Dotfile(relativePath: ".config/ghostty/config", group: .tools),
    ]

    /// Top-level dotfiles that are machine-written state, not configuration.
    static let ignoredNames: Set<String> = [
        ".DS_Store",
        ".CFUserTextEncoding",
        ".lesshst",
        ".viminfo",
        ".wget-hsts",
        ".Xauthority",
    ]

    /// Whether a top-level file name looks like configuration someone edits.
    static func isConfigurationName(_ name: String) -> Bool {
        guard name.hasPrefix("."), !ignoredNames.contains(name) else { return false }
        // Shell and REPL history files (.zsh_history, .python_history) and
        // zsh's completion cache (.zcompdump-*) change on their own.
        return !name.hasSuffix("_history") && !name.hasPrefix(".zcompdump")
    }
}
