import Testing
@testable import DotdrawerCore

@Test func displaysModifiersInMacOSOrder() {
    let shortcut = Shortcut(keyCode: 2, modifiers: [.command, .shift, .option, .control], keyLabel: "D")

    #expect(shortcut.displayString == "⌃⌥⇧⌘D")
}

@Test func requiresControlOptionOrCommandForGlobalUse() {
    #expect(!Shortcut(keyCode: 2, modifiers: [], keyLabel: "D").isAllowedAsGlobal)
    #expect(!Shortcut(keyCode: 2, modifiers: [.shift], keyLabel: "D").isAllowedAsGlobal)
    #expect(Shortcut(keyCode: 2, modifiers: [.option], keyLabel: "D").isAllowedAsGlobal)
    #expect(Shortcut(keyCode: 2, modifiers: [.shift, .command], keyLabel: "D").isAllowedAsGlobal)
}

@Test func usesTheDefaultUntilOneIsSaved() {
    #expect(ShortcutStore(defaults: isolatedDefaults()).load() == .defaultOpenDrawer)
}

@Test func savesARecordedShortcut() {
    let store = ShortcutStore(defaults: isolatedDefaults())
    let shortcut = Shortcut(keyCode: 49, modifiers: [.option], keyLabel: "Space")

    store.save(shortcut)

    #expect(store.load() == shortcut)
}

@Test func clearingStaysClearedInsteadOfRestoringTheDefault() {
    let store = ShortcutStore(defaults: isolatedDefaults())

    store.save(nil)

    #expect(store.load() == nil)
}
