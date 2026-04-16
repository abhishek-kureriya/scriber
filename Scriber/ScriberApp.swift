import SwiftUI
import AVFoundation
import Speech
import Carbon.HIToolbox
import ServiceManagement

@main
struct ScriberApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings()
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var recordingVM: RecordingViewModel!
    var settingsWindow: NSWindow?
    let textInput = TextInputService()
    var globalMonitor: Any?
    var localMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.clear()
        Log.write("App launched")

        recordingVM = RecordingViewModel(settings: settings)
        recordingVM.onDone = { [weak self] text in
            self?.pasteResult(text)
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 220)
        popover.behavior = .applicationDefined
        popover.contentViewController = NSHostingController(
            rootView: OverlayView(
                vm: recordingVM,
                settings: settings,
                onOpenSettings: { [weak self] in self?.openSettings() },
                onClose: { [weak self] in self?.popover.performClose(nil) }
            )
        )

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic.circle.fill", accessibilityDescription: "Scriber")
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        registerGlobalHotkey()
        checkPermissions()
    }

    // MARK: - Global Hotkey (Cmd+Shift+R)

    private func registerGlobalHotkey() {
        let flags: NSEvent.ModifierFlags = [.command, .shift]
        let keyCode: UInt16 = 15 // R key

        // Monitor when other apps are focused
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == flags && event.keyCode == keyCode {
                DispatchQueue.main.async { self?.toggleRecordingFromHotkey() }
            }
        }

        // Monitor when our app is focused
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == flags && event.keyCode == keyCode {
                DispatchQueue.main.async { self?.toggleRecordingFromHotkey() }
                return nil // consume the event
            }
            return event
        }

        Log.write("Global hotkey registered: Cmd+Shift+R")
    }

    func toggleRecordingFromHotkey() {
        switch recordingVM.state {
        case .idle:
            textInput.rememberFocusedApp()
            Log.write("Hotkey: start recording (app: \(textInput.previousAppName ?? "nil"))")
            recordingVM.startRecording()
            // Show popover so user can see recording state
            if !popover.isShown, let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
            updateMenuBarIcon(recording: true)
        case .recording:
            Log.write("Hotkey: stop recording")
            recordingVM.stopAndProcess()
            updateMenuBarIcon(recording: false)
        default:
            break // ignore during processing
        }
    }

    private func updateMenuBarIcon(recording: Bool) {
        if let button = statusItem.button {
            if recording {
                button.image = NSImage(systemSymbolName: "mic.circle.fill", accessibilityDescription: "Scriber - Recording")
                button.contentTintColor = .red
            } else {
                button.image = NSImage(systemSymbolName: "mic.circle.fill", accessibilityDescription: "Scriber")
                button.contentTintColor = nil
            }
        }
    }

    // MARK: - Status Item

    @objc func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
            menu.addItem(NSMenuItem(title: "Open Transcripts", action: #selector(openTranscripts), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Hotkey: Cmd+Shift+R", action: nil, keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            DispatchQueue.main.async { self.statusItem.menu = nil }
        } else {
            togglePopover()
        }
    }

    func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            textInput.rememberFocusedApp()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func pasteResult(_ text: String) {
        Log.write("pasteResult: \(text.prefix(50))...")
        popover.performClose(nil)
        recordingVM.reset()
        updateMenuBarIcon(recording: false)

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        if let appName = textInput.previousAppName {
            Log.write("Switching to \(appName) and pasting")
            textInput.activateAndPaste(appName)
        }
    }

    @objc func openSettings() {
        popover.performClose(nil)
        if let w = settingsWindow {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let hc = NSHostingController(rootView: SettingsView().environmentObject(settings))
        let w = NSWindow(contentViewController: hc)
        w.title = "Scriber Settings"
        w.setContentSize(NSSize(width: 500, height: 560))
        w.styleMask = [.titled, .closable]
        w.center()
        w.isReleasedWhenClosed = false
        w.makeKeyAndOrderFront(nil)
        settingsWindow = w
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openTranscripts() {
        TranscriptExporter.openFolder()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private func checkPermissions() {
        if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { _ in }
        }
        if SFSpeechRecognizer.authorizationStatus() == .notDetermined {
            SFSpeechRecognizer.requestAuthorization { _ in }
        }
    }
}
