import AppKit

// Menu bar apps run as "accessory" apps: no Dock icon and no main menu bar.
// Setting this in code means we don't need an Info.plist with LSUIElement yet.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
