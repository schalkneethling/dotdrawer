import AppKit
import Sparkle

/// Checks for new versions of dotdrawer with Sparkle. The feed URL and the
/// public key that verifies each update come from Info.plist.
///
/// A menu bar app has no window of its own, so an update alert that appears
/// later in the day would open behind whatever the user is working in.
/// Instead, Sparkle shows scheduled alerts only when they can have focus,
/// near launch, and otherwise leaves the update for the drawer to announce.
@MainActor
final class Updater: NSObject {
    private lazy var controller = SPUStandardUpdaterController(
        startingUpdater: false,
        updaterDelegate: nil,
        userDriverDelegate: self
    )

    /// The version a scheduled check found and left for the drawer to
    /// announce, until the user deals with it.
    private(set) var pendingVersion: String?

    /// Starts scheduled checks. Running unbundled with `swift run` there is
    /// no Info.plist with a feed URL, and Sparkle would report that as an
    /// error, so the updater stays off there.
    func start() {
        guard Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") != nil else { return }
        controller.startUpdater()
    }

    /// False while a check or an update is already in progress, or when the
    /// updater never started.
    var canCheckForUpdates: Bool {
        controller.updater.canCheckForUpdates
    }

    func checkForUpdates() {
        // An accessory app isn't active after a menu click, so without this
        // the update window opens behind the frontmost app.
        NSApp.activate()
        controller.checkForUpdates(nil)
    }
}

// Sparkle calls its user driver delegate on the main thread, but the
// Objective-C protocol doesn't say so, hence @preconcurrency.
extension Updater: @preconcurrency SPUStandardUserDriverDelegate {
    var supportsGentleScheduledUpdateReminders: Bool {
        true
    }

    func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool {
        immediateFocus
    }

    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        // When Sparkle shows the update itself, including every check the
        // user starts, there is nothing for the drawer to announce.
        guard !handleShowingUpdate else { return }
        pendingVersion = update.displayVersionString
    }

    func standardUserDriverWillFinishUpdateSession() {
        pendingVersion = nil
    }
}
