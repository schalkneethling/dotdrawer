import AppKit
import Carbon.HIToolbox
import DotdrawerCore
import SwiftUI

/// A button that shows the current shortcut and, once clicked, records the
/// next key combination the user presses.
struct ShortcutRecorder: View {
    let shortcut: Shortcut?
    let onStart: () -> Void
    let onRecord: (Shortcut) -> Void
    let onCancel: () -> Void

    @State private var isRecording = false
    @State private var hint: String?
    @State private var monitor: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: startRecording) {
                Text(isRecording ? "Type a shortcut…" : (shortcut?.displayString ?? "None"))
                    .frame(minWidth: 120)
            }
            if isRecording {
                Text(hint ?? "Press Escape to cancel.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onDisappear(perform: cancel)
    }

    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        hint = nil
        onStart()
        // A local monitor only sees key presses while this app's window is
        // focused, which it is while the user records.
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handle(event)
            return nil
        }
    }

    private func handle(_ event: NSEvent) {
        let modifiers = Self.modifiers(from: event.modifierFlags)
        if event.keyCode == UInt16(kVK_Escape) && modifiers.isEmpty {
            cancel()
            return
        }

        let recorded = Shortcut(keyCode: UInt32(event.keyCode), modifiers: modifiers, keyLabel: Self.label(for: event))
        guard recorded.isAllowedAsGlobal else {
            hint = "Include ⌃, ⌥, or ⌘ so the shortcut doesn't take over a key you type."
            return
        }
        stopMonitoring()
        onRecord(recorded)
    }

    private func cancel() {
        guard isRecording else { return }
        stopMonitoring()
        onCancel()
    }

    private func stopMonitoring() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        isRecording = false
    }

    private static func modifiers(from flags: NSEvent.ModifierFlags) -> Shortcut.Modifiers {
        var modifiers: Shortcut.Modifiers = []
        if flags.contains(.control) { modifiers.insert(.control) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        if flags.contains(.command) { modifiers.insert(.command) }
        return modifiers
    }

    /// Keys whose typed character is invisible or unhelpful get a name.
    private static let namedKeys: [Int: String] = [
        kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
        kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
        kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
    ]

    private static func label(for event: NSEvent) -> String {
        if let name = namedKeys[Int(event.keyCode)] { return name }
        let character = event.charactersIgnoringModifiers?.uppercased() ?? ""
        return character.isEmpty ? "Key \(event.keyCode)" : character
    }
}
