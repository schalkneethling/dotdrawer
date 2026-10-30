import Foundation
import Testing
@testable import DotdrawerCore

/// A throwaway home folder, removed when the test finishes.
private final class TemporaryHome {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory.appending(path: "dotdrawer-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }

    func addFile(_ relativePath: String) throws {
        let fileURL = url.appending(path: relativePath)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data().write(to: fileURL)
    }

    func addFolder(_ relativePath: String) throws {
        try FileManager.default.createDirectory(at: url.appending(path: relativePath), withIntermediateDirectories: true)
    }
}

@Test func findsNestedCatalogFiles() throws {
    let home = try TemporaryHome()
    try home.addFile(".claude/CLAUDE.md")
    try home.addFile(".codex/AGENTS.md")

    let found = DotfileScanner(home: home.url).scan()

    #expect(found == [
        Dotfile(relativePath: ".claude/CLAUDE.md", group: .agents),
        Dotfile(relativePath: ".codex/AGENTS.md", group: .agents),
    ])
}

@Test func listsUnknownTopLevelDotfilesAsOther() throws {
    let home = try TemporaryHome()
    try home.addFile(".zshrc")
    try home.addFile(".myapprc")

    let found = DotfileScanner(home: home.url).scan()

    // .zshrc is in the catalog, so it keeps its Shell group instead of
    // showing up a second time under Other.
    #expect(found == [
        Dotfile(relativePath: ".zshrc", group: .shell),
        Dotfile(relativePath: ".myapprc", group: .other),
    ])
}

@Test func skipsStateFilesFoldersAndNonDotfiles() throws {
    let home = try TemporaryHome()
    try home.addFile(".DS_Store")
    try home.addFile(".zsh_history")
    try home.addFile(".zcompdump-host-5.9")
    try home.addFile("notes.txt")
    try home.addFolder(".config")

    #expect(DotfileScanner(home: home.url).scan().isEmpty)
}

@Test func includesSymlinkedDotfiles() throws {
    let home = try TemporaryHome()
    try home.addFile("dotfiles/zshrc")
    try FileManager.default.createSymbolicLink(
        at: home.url.appending(path: ".zshrc"),
        withDestinationURL: home.url.appending(path: "dotfiles/zshrc")
    )

    #expect(DotfileScanner(home: home.url).scan() == [Dotfile(relativePath: ".zshrc", group: .shell)])
}
