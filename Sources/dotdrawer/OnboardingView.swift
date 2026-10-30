import DotdrawerCore
import SwiftUI

struct OnboardingView: View {
    @Bindable var model: OnboardingModel

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
                Button("Done") { model.finish() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 440, height: 480)
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
