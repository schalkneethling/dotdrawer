import Testing
@testable import DotdrawerCore

private let home = "/Users/someone"

private func app(_ name: String, _ bundleIdentifier: String, _ path: String) -> EditorApp {
    EditorApp(bundleIdentifier: bundleIdentifier, name: name, path: path)
}

@Test func keepsAppsInApplicationFoldersSortedByName() {
    let editors = EditorCatalog.editors(
        from: [
            app("Zed", "dev.zed.Zed", "/Applications/Zed.app"),
            app("TextEdit", "com.apple.TextEdit", "/System/Applications/TextEdit.app"),
            app("BBEdit", "com.barebones.bbedit", home + "/Applications/BBEdit.app"),
            app("Script Editor", "com.apple.ScriptEditor2", "/System/Applications/Utilities/Script Editor.app"),
        ],
        browserIdentifiers: [],
        homePath: home
    )

    #expect(editors.map(\.name) == ["BBEdit", "Script Editor", "TextEdit", "Zed"])
}

@Test func skipsAppsInsideOtherAppsAndOutsideApplicationFolders() {
    let editors = EditorCatalog.editors(
        from: [
            app("Instruments", "com.apple.dt.Instruments", "/Applications/Xcode.app/Contents/Applications/Instruments.app"),
            app("Chromium", "org.chromium.Chromium", home + "/Library/Caches/ms-playwright/chrome-mac/Chromium.app"),
        ],
        browserIdentifiers: [],
        homePath: home
    )

    #expect(editors.isEmpty)
}

@Test func skipsBrowsers() {
    let editors = EditorCatalog.editors(
        from: [
            app("Google Chrome", "com.google.Chrome", "/Applications/Google Chrome.app"),
            app("Zed", "dev.zed.Zed", "/Applications/Zed.app"),
        ],
        browserIdentifiers: ["com.google.Chrome"],
        homePath: home
    )

    #expect(editors.map(\.name) == ["Zed"])
}

@Test func keepsTheFirstCopyOfEachApp() {
    let editors = EditorCatalog.editors(
        from: [
            app("Warp", "dev.warp.Warp-Stable", "/Applications/Warp.app"),
            app("Warp", "dev.warp.Warp-Stable", home + "/Applications/Warp.app"),
        ],
        browserIdentifiers: [],
        homePath: home
    )

    #expect(editors == [app("Warp", "dev.warp.Warp-Stable", "/Applications/Warp.app")])
}
