import AppKit

final class TextInputService {
    private(set) var previousApp: NSRunningApplication?
    private var observer: NSObjectProtocol?

    var previousAppName: String? { previousApp?.localizedName }

    init() {
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier != Bundle.main.bundleIdentifier else { return }
            self?.previousApp = app
        }

        if let app = NSWorkspace.shared.frontmostApplication,
           app.bundleIdentifier != Bundle.main.bundleIdentifier {
            previousApp = app
        }
    }

    deinit {
        if let observer { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
    }

    func rememberFocusedApp() {
        for app in NSWorkspace.shared.runningApplications where app.isActive {
            if app.bundleIdentifier != Bundle.main.bundleIdentifier {
                previousApp = app
                return
            }
        }
    }

    func activateAndPaste(_ appName: String) {
        // Activate the app
        if let app = previousApp {
            app.activate(options: .activateIgnoringOtherApps)
        }

        // Wait for activation, then paste via CGEvent
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let src = CGEventSource(stateID: .combinedSessionState)
            let down = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true) // 0x09 = V
            down?.flags = .maskCommand
            down?.post(tap: .cghidEventTap)

            let up = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)
            up?.flags = .maskCommand
            up?.post(tap: .cghidEventTap)

            Log.write("CGEvent paste sent")
        }
    }

    @discardableResult
    private func runAppleScript(_ source: String) -> Bool {
        guard let script = NSAppleScript(source: source) else { return false }
        var err: NSDictionary?
        script.executeAndReturnError(&err)
        if let err { Log.write("AppleScript error: \(err)") }
        return err == nil
    }
}
