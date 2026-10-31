import AppKit

// Menu bar apps run as "accessory" apps: no Dock icon and no main menu bar.
// The bundle's Info.plist says so too, with LSUIElement, but `swift run`
// starts the bare executable without that Info.plist, so set it here as well.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
