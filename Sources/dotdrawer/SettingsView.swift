import DotdrawerCore
import SwiftUI

struct SettingsView: View {
    @Bindable var model: SettingsModel

    var body: some View {
        switch model.step {
        case .access:
            accessStep
        case .choose:
            chooseStep
        }
    }

    private var accessStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Give dotdrawer access to your home folder")
                .font(.title2.bold())
            Text("dotdrawer looks for agent configs and other dotfiles in your home folder. macOS asks you to choose the folder once, and dotdrawer remembers your answer.")
                .fixedSize(horizontal: false, vertical: true)
            if let error = model.accessError {
                Text(error)
                    .foregroundStyle(.red)
            }
            HStack {
                Spacer()
                Button("Choose Home Folder…") { model.grantAccess() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 440)
    }

    private var chooseStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose the files to show")
                .font(.title2.bold())
            Text("Selected files appear in the menu bar drawer.")
                .foregroundStyle(.secondary)

            if model.found.isEmpty {
                Text("No dotfiles found in your home folder.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(model.sections, id: \.group) { section in
                        Section(section.group.rawValue) {
                            ForEach(section.files, id: \.relativePath) { file in
                                Toggle(file.displayPath, isOn: binding(for: file))
                                    .toggleStyle(.checkbox)
                            }
                        }
                    }
                }
            }

            HStack {
                Button("Scan Again") { model.rescan() }
                Spacer()
            }

            Divider()

            generalSettings

            HStack {
                Spacer()
                Button("Done") { model.close() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 480, height: 640)
    }

    /// Labels on the left, controls on the right, like macOS settings.
    private var generalSettings: some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 14) {
            GridRow {
                Text("Open files with")
                    .gridColumnAlignment(.trailing)
                editorPicker
            }
            GridRow {
                Text("Open drawer with")
                shortcutSetting
            }
            GridRow {
                Text("Startup")
                loginSetting
            }
        }
    }

    private var shortcutSetting: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                ShortcutRecorder(
                    shortcut: model.shortcut,
                    onStart: model.beginRecordingShortcut,
                    onRecord: model.recordShortcut,
                    onCancel: model.cancelRecordingShortcut
                )
                if model.shortcut != nil {
                    Button("Clear") { model.clearShortcut() }
                }
            }
            if let problem = model.shortcutProblem {
                Text(problem)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var loginSetting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Launch dotdrawer at login", isOn: Binding(
                get: { model.launchesAtLogin },
                set: { model.setLaunchAtLogin($0) }
            ))
            if model.loginState == .needsApproval {
                Text("Turned off in System Settings. Approve dotdrawer under Login Items to start it at login.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Open Login Items Settings") { model.openLoginItemsSettings() }
            }
            if let error = model.loginError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var editorPicker: some View {
        HStack {
            Picker("Open files with", selection: $model.editorBundleIdentifier) {
                Text("Default app for each file").tag(String?.none)
                Divider()
                ForEach(model.editors, id: \.bundleIdentifier) { editor in
                    Label {
                        Text(editor.name)
                    } icon: {
                        Image(nsImage: InstalledEditors.icon(for: editor))
                    }
                    .tag(Optional(editor.bundleIdentifier))
                }
            }
            // The grid row already shows the label.
            .labelsHidden()
            Button("Other…") { model.chooseOtherEditor() }
        }
    }

    private func binding(for file: Dotfile) -> Binding<Bool> {
        Binding(
            get: { model.selectedPaths.contains(file.relativePath) },
            set: { isSelected in
                if isSelected {
                    model.selectedPaths.insert(file.relativePath)
                } else {
                    model.selectedPaths.remove(file.relativePath)
                }
            }
        )
    }
}
