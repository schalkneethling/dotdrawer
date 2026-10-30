import Foundation
import Testing
@testable import DotdrawerCore

@Test func noEditorUntilOneIsSaved() {
    #expect(EditorPreference(defaults: isolatedDefaults()).load() == nil)
}

@Test func savesTheChosenEditor() {
    let preference = EditorPreference(defaults: isolatedDefaults())

    preference.save("dev.zed.Zed")

    #expect(preference.load() == "dev.zed.Zed")
}

@Test func savingNilReturnsToDefaultApps() {
    let preference = EditorPreference(defaults: isolatedDefaults())
    preference.save("dev.zed.Zed")

    preference.save(nil)

    #expect(preference.load() == nil)
}
