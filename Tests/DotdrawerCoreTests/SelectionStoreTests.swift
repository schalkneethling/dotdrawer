import Foundation
import Testing
@testable import DotdrawerCore

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

@Test func tellsAnEmptySavedSelectionFromNoneSaved() {
    let store = SelectionStore(defaults: isolatedDefaults())
    #expect(!store.hasSavedSelection)

    store.save([])

    #expect(store.hasSavedSelection)
    #expect(store.load().isEmpty)
}

@Test func dropsEntriesWithUnknownGroups() {
    let defaults = isolatedDefaults()
    defaults.set([["path": ".zshrc", "group": "Removed group"]], forKey: "selectedDotfiles")

    #expect(SelectionStore(defaults: defaults).load().isEmpty)
}
