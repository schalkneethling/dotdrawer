import DotdrawerCore
import Observation

/// State for the onboarding window: first the access step, then the
/// checklist of found files and the choice of editor.
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

    /// Apps offered in the Open With picker.
    private(set) var editors: [EditorApp]
    /// The chosen editor, or nil for each file's default app.
    var editorBundleIdentifier: String?

    private let homeAccess: HomeAccess
    private let store: SelectionStore
    private let editorPreference: EditorPreference
    private let onFinish: () -> Void

    init(homeAccess: HomeAccess, store: SelectionStore, editorPreference: EditorPreference, onFinish: @escaping () -> Void) {
        self.homeAccess = homeAccess
        self.store = store
        self.editorPreference = editorPreference
        self.onFinish = onFinish
        var editors = InstalledEditors.list()
        var saved = editorPreference.load()
        // An editor picked with Other… isn't in the generated list, so add
        // it back. One that has been uninstalled falls back to default apps,
        // which is also what opening a file does.
        if let bundleIdentifier = saved, !editors.contains(where: { $0.bundleIdentifier == bundleIdentifier }) {
            if let editor = InstalledEditors.editor(withBundleIdentifier: bundleIdentifier) {
                editors.append(editor)
            } else {
                saved = nil
            }
        }
        self.editors = editors
        editorBundleIdentifier = saved
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

    /// Adds an app the list didn't include and selects it.
    func chooseOtherEditor() {
        guard let editor = InstalledEditors.pickOther() else { return }
        if !editors.contains(where: { $0.bundleIdentifier == editor.bundleIdentifier }) {
            editors.append(editor)
        }
        editorBundleIdentifier = editor.bundleIdentifier
    }

    func finish() {
        store.save(found.filter { selectedPaths.contains($0.relativePath) })
        editorPreference.save(editorBundleIdentifier)
        onFinish()
    }
}
