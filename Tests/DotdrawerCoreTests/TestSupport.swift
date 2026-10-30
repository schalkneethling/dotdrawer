import Foundation

/// A defaults domain of its own, so tests never touch the app's real settings.
func isolatedDefaults() -> UserDefaults {
    let suiteName = "dotdrawer-tests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}
