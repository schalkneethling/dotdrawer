import DotdrawerCore
import Observation

/// State for the onboarding window: first the access step, then the
/// checklist of found files.
@MainActor
@Observable
final class OnboardingModel {
    enum Step {
        case access
        case choose
    }

    private(set) var step: Step
    private(set) var found: [Dotfile] = []
    var selectedPaths: Set<String> = []
    private(set) var accessError: String?

    private let homeAccess: HomeAccess
    private let store: SelectionStore
    private let onFinish: () -> Void

    init(homeAccess: HomeAccess, store: SelectionStore, onFinish: @escaping () -> Void) {
        self.homeAccess = homeAccess
        self.store = store
        self.onFinish = onFinish
        step = homeAccess.grantedHome == nil ? .access : .choose
        if step == .choose {
            rescan()
        }
    }

    /// Found files grouped for display, skipping empty groups.
    var sections: [(group: DotfileGroup, files: [Dotfile])] {
        DotfileGroup.allCases.compactMap { group in
            let files = found.filter { $0.group == group }
            return files.isEmpty ? nil : (group, files)
        }
    }

    func grantAccess() {
        switch homeAccess.request() {
        case .granted:
            accessError = nil
            step = .choose
            rescan()
        case .wrongFolder:
            accessError = "That isn't your home folder. Choose \(homeAccess.expectedHome.path)."
        case .cancelled:
            break
        }
    }

    /// Scans again, keeping the user's saved choices. On the first run
    /// nothing is saved yet, so agent configs start selected because they
    /// are what dotdrawer is for.
    func rescan() {
        guard let home = homeAccess.grantedHome else { return }
        found = DotfileScanner(home: home).scan()

        let saved = store.load()
        selectedPaths = saved.isEmpty
            ? Set(found.filter { $0.group == .agents }.map(\.relativePath))
            : Set(saved.map(\.relativePath))
    }

    func finish() {
        store.save(found.filter { selectedPaths.contains($0.relativePath) })
        onFinish()
    }
}
