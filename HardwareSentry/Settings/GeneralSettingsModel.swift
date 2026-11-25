import AppKit
import Combine
import ServiceManagement
import SignalCore

/// Where the application puts its own icon.
///
/// Four states rather than two switches, because "menu bar" and "dock" are not independent
/// in practice: hiding both is a real choice somebody makes deliberately, and offering it
/// as two checkboxes invites arriving at it by accident and then not knowing how to get
/// the application back.
enum IconVisibility: Int, CaseIterable, Identifiable {
    case menuBar = 0
    case dock = 1
    case both = 2
    case none = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .menuBar: return "Show icon in the menubar"
        case .dock: return "Show icon in the dock"
        case .both: return "Show icon in both"
        case .none: return "No icon visible"
        }
    }

    var showsMenuBarIcon: Bool { self == .menuBar || self == .both }
    var showsDockIcon: Bool { self == .dock || self == .both }

    /// A dock icon is what makes an application "regular"; without one it is an accessory
    /// that lives entirely in the menu bar.
    var activationPolicy: NSApplication.ActivationPolicy {
        showsDockIcon ? .regular : .accessory
    }
}

/// The General tab: where the application shows itself, whether it starts with the Mac,
/// what it says at launch, and backing all of that up.
@MainActor
final class GeneralSettingsModel: ObservableObject {
    private let preferences: NotificationPreferencesStore
    private let defaults: UserDefaults

    @Published private var revision = 0

    init(preferences: NotificationPreferencesStore, defaults: UserDefaults = .standard) {
        self.preferences = preferences
        self.defaults = defaults
    }

    // MARK: - Where the icon lives

    var iconVisibility: IconVisibility {
        get {
            _ = revision
            return IconVisibility(rawValue: defaults.integer(forKey: Self.visibilityKey)) ?? .menuBar
        }
        set {
            // Hiding every way of reaching the application is worth one question. The
            // answer can be suppressed, because somebody who meant it the first time does
            // not need asking again.
            if newValue == .none, !defaults.bool(forKey: Self.suppressNoIconWarningKey), !confirmHidingEverything() {
                revision += 1   // redraws the picker back to what it was
                return
            }
            defaults.set(newValue.rawValue, forKey: Self.visibilityKey)
            revision += 1
            apply(newValue)
        }
    }

    /// - Returns: whether to go ahead.
    private func confirmHidingEverything() -> Bool {
        let alert = NSAlert()
        alert.messageText = "HardwareSentry will keep running with no icon anywhere."
        alert.informativeText = """
            It will carry on watching your hardware and showing notifications, but there             will be no menu bar item and no dock icon to click.

            To get back to these settings, open HardwareSentry again from Applications or             Launchpad.
            """
        alert.addButton(withTitle: "Hide the Icon")
        alert.addButton(withTitle: "Cancel")
        alert.showsSuppressionButton = true
        NSApp.activate(ignoringOtherApps: true)

        guard alert.runModal() == .alertFirstButtonReturn else { return false }
        if alert.suppressionButton?.state == .on {
            defaults.set(true, forKey: Self.suppressNoIconWarningKey)
        }
        return true
    }

    /// Called at launch as well as on change, so the choice from last time is in force
    /// before anybody sees the application.
    func applyStoredIconVisibility() {
        apply(iconVisibility)
    }

    /// Applies the choice at once, so picking one has a visible result.
    ///
    /// With one exception: dropping to `.accessory` while these settings are open would
    /// pull the window out from under whoever is reading it. So the application stays
    /// `.regular` for as long as the window is up, and `applyOnSettingsWindowClose()`
    /// finishes the job. Opening the window does the same in reverse — a menu-bar-only
    /// application has to become `.regular` briefly to take focus at all.
    private func apply(_ visibility: IconVisibility) {
        guard !isSettingsWindowOpen else { return }
        NSApplication.shared.setActivationPolicy(visibility.activationPolicy)
    }

    /// Called as the settings window appears and disappears, so the policy can be held at
    /// `.regular` while it is on screen.
    @Published private(set) var isSettingsWindowOpen = false

    func settingsWindowOpened() {
        isSettingsWindowOpen = true
        NSApplication.shared.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func settingsWindowClosed() {
        isSettingsWindowOpen = false
        NSApplication.shared.setActivationPolicy(iconVisibility.activationPolicy)
        // Focus goes back to whatever was in front before, which for a menu-bar
        // application is what somebody expects when they close its settings.
        if !iconVisibility.showsDockIcon { NSApplication.shared.hide(nil) }
    }

    private static let visibilityKey = "HardwareSentry.IconVisibility"
    private static let suppressNoIconWarningKey = "HardwareSentry.SuppressNoIconWarning"

    // MARK: - Starting with the Mac

    /// Read from the system rather than from a stored flag: somebody can turn a login item
    /// off in System Settings, and a remembered "yes" would then be a lie.
    var startsAtLogin: Bool {
        get {
            _ = revision
            return Self.loginAgentIsInstalled
        }
        set {
            if newValue { Self.installLoginAgent() } else { Self.removeLoginAgent() }
            // Drop any registration made by earlier builds through SMAppService: on an
            // ad-hoc-signed build every rebuild looked like a new login item to macOS, so the
            // app was listed twice and the switch read back OFF. A LaunchAgent is keyed by its
            // fixed label, so it cannot duplicate.
            try? SMAppService.mainApp.unregister()
            revision += 1
        }
    }

    private static let loginAgentLabel = Bundle.main.bundleIdentifier ?? "com.jensyleo.hardwaresentry"
    private static var loginAgentURL: URL {
        URL(fileURLWithPath: NSHomeDirectory() + "/Library/LaunchAgents/\(loginAgentLabel).plist")
    }

    private static var loginAgentIsInstalled: Bool {
        guard let plist = NSDictionary(contentsOf: loginAgentURL),
              let args = plist["ProgramArguments"] as? [String], let exe = args.first else { return false }
        return FileManager.default.isExecutableFile(atPath: exe)
    }

    private static func installLoginAgent() {
        guard let exe = Bundle.main.executablePath else { return }
        let plist: [String: Any] = [
            "Label": loginAgentLabel,
            "ProgramArguments": [exe],
            "RunAtLoad": true,
            "ProcessType": "Interactive",
        ]
        try? FileManager.default.createDirectory(at: loginAgentURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        (plist as NSDictionary).write(to: loginAgentURL, atomically: true)
    }

    private static func removeLoginAgent() {
        try? FileManager.default.removeItem(at: loginAgentURL)
    }

    /// The choice is stored in the agent file, whose path is not tied to a build, so a
    /// reinstall at the same location keeps it. Re-pointed at the running binary at every
    /// launch in case the app was moved.
    func refreshLoginAgentAtLaunch() {
        if Self.loginAgentIsInstalled || FileManager.default.fileExists(atPath: Self.loginAgentURL.path) {
            Self.installLoginAgent()
        }
        try? SMAppService.mainApp.unregister()
    }

    // MARK: - What launching says

    var showsConnectedDevicesAtLaunch: Bool {
        get {
            _ = revision
            return preferences.announcesWhatIsAlreadyThere
        }
        set {
            preferences.announcesWhatIsAlreadyThere = newValue
            revision += 1
        }
    }
}
