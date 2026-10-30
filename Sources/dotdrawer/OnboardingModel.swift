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
    private(set) var accessError: String?

    // Choices save as soon as they change, like a macOS settings window, so
    // closing the window any way (Done or the red button) keeps them.

    /// The ticked files.
    var selectedPaths: Set<String> = [] {
        didSet { store.save(found.filter { selectedPaths.contains($0.relativePath) }) }
    }

    /// Apps offered in the Open With picker.
    private(set) var editors: [EditorApp]
    /// The chosen editor, or nil for each file's default app.
    var editorBundleIdentifier: String? {
        didSet { editorPreference.save(editorBundleIdentifier) }
    }

    private let homeAccess: HomeAccess
    private let store: SelectionStore
    private let editorPreference: EditorPreference
    private let onClose: () -> Void

    init(homeAccess: HomeAccess, store: SelectionStore, editorPreference: EditorPreference, onClose: @escaping () -> Void) {
        self.homeAccess = homeAccess
        self.store = store
        self.editorPreference = editorPreference
        self.onClose = onClose
        let choices = InstalledEditors.choices(saved: editorPreference.load())
        editors = choices.editors
        editorBundleIdentifier = choices.current
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
    /// nothing is saved yet, so agent configs start selected (and saved)
    /// because they are what dotdrawer is for.
    func rescan() {
        guard let home = homeAccess.grantedHome else { return }
        found = DotfileScanner(home: home).scan()

        selectedPaths = store.hasSavedSelection
            ? Set(store.load().map(\.relativePath))
            : Set(found.filter { $0.group == .agents }.map(\.relativePath))
    }

    /// Adds an app the list didn't include and selects it.
    func chooseOtherEditor() {
        guard let editor = InstalledEditors.pickOther() else { return }
        include(editor)
        editorBundleIdentifier = editor.bundleIdentifier
    }

    /// Selects an editor chosen elsewhere, such as the menu bar submenu.
    func showEditor(_ bundleIdentifier: String?) {
        if let bundleIdentifier, let editor = InstalledEditors.editor(withBundleIdentifier: bundleIdentifier) {
            include(editor)
        }
        editorBundleIdentifier = bundleIdentifier
    }

    private func include(_ editor: EditorApp) {
        if !editors.contains(where: { $0.bundleIdentifier == editor.bundleIdentifier }) {
            editors.append(editor)
        }
    }

    func close() {
        onClose()
    }
}
