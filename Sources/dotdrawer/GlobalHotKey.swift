import Carbon.HIToolbox
import DotdrawerCore

/// A system-wide keyboard shortcut, registered with Carbon's hot key API.
/// Unlike watching all key presses, this needs no Accessibility permission:
/// macOS delivers only the one registered combination to the app.
@MainActor
final class GlobalHotKey {
    enum RegistrationError: Error {
        /// Another app already registered this combination.
        case takenByAnotherApp
        case failed(OSStatus)
    }

    private let onPress: () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    init(onPress: @escaping () -> Void) {
        self.onPress = onPress
    }

    /// Replaces the registered shortcut. Passing nil only unregisters.
    func register(_ shortcut: Shortcut?) throws(RegistrationError) {
        unregister()
        guard let shortcut else { return }
        try installHandlerIfNeeded()

        var ref: EventHotKeyRef?
        // The signature and id identify this app's hot key in the event.
        let id = EventHotKeyID(signature: OSType(0x6474_6472), id: 1) // "dtdr"
        // macOS reports a clash only between exclusive registrations: an app
        // that registers the same keys without this option goes unnoticed.
        // Registering exclusively also stops a later app from claiming the
        // shortcut exclusively out from under dotdrawer.
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            Self.carbonModifiers(shortcut.modifiers),
            id,
            GetApplicationEventTarget(),
            OptionBits(kEventHotKeyExclusive),
            &ref
        )
        switch status {
        case noErr:
            hotKeyRef = ref
        case OSStatus(eventHotKeyExistsErr):
            throw .takenByAnotherApp
        default:
            throw .failed(status)
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRef = nil
    }

    private func installHandlerIfNeeded() throws(RegistrationError) {
        guard handlerRef == nil else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        // Carbon calls back through a C function, which can't capture
        // `self`, so pass it along as an unretained pointer. The handler
        // lives as long as the app, like this object.
        let userData = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
            // Carbon delivers application events on the main thread.
            MainActor.assumeIsolated { hotKey.onPress() }
            return noErr
        }, 1, &eventType, userData, &handlerRef)

        guard status == noErr else { throw .failed(status) }
    }

    private static func carbonModifiers(_ modifiers: Shortcut.Modifiers) -> UInt32 {
        var carbon: UInt32 = 0
        if modifiers.contains(.control) { carbon |= UInt32(controlKey) }
        if modifiers.contains(.option) { carbon |= UInt32(optionKey) }
        if modifiers.contains(.shift) { carbon |= UInt32(shiftKey) }
        if modifiers.contains(.command) { carbon |= UInt32(cmdKey) }
        return carbon
    }
}
