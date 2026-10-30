import Foundation
import Testing
@testable import DotdrawerCore

/// A defaults domain of its own, so tests never touch the app's real settings.
private func isolatedDefaults() -> UserDefaults {
    let suiteName = "dotdrawer-tests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}

@Test func startsEmpty() {
    #expect(SelectionStore(defaults: isolatedDefaults()).load().isEmpty)
}

@Test func roundTripsSelectionInOrder() {
    let store = SelectionStore(defaults: isolatedDefaults())
    let selection = [
        Dotfile(relativePath: ".zshrc", group: .shell),
        Dotfile(relativePath: ".claude/CLAUDE.md", group: .agents),
    ]

    store.save(selection)

    #expect(store.load() == selection)
}

@Test func dropsEntriesWithUnknownGroups() {
    let defaults = isolatedDefaults()
    defaults.set([["path": ".zshrc", "group": "Removed group"]], forKey: "selectedDotfiles")

    #expect(SelectionStore(defaults: defaults).load().isEmpty)
}
