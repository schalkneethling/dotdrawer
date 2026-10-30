import ServiceManagement

/// Starts dotdrawer when the user logs in, through macOS's login items.
@MainActor
enum LoginItem {
    enum State {
        case enabled
        case disabled
        /// Registered, but the user turned it off in System Settings, so it
        /// only starts after they approve it there.
        case needsApproval
    }

    static var state: State {
        switch SMAppService.mainApp.status {
        case .enabled: .enabled
        case .requiresApproval: .needsApproval
        default: .disabled
        }
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    static func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
