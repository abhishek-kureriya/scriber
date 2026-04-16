import SwiftUI
import AVFoundation
import Speech

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var showingAPIKey = false
    @State private var languages: [(identifier: String, name: String)] = []

    @State private var micStatus: AVAuthorizationStatus = .notDetermined
    @State private var speechStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @State private var accessibilityGranted: Bool = false

    enum GatewayStatus {
        case unknown
        case checking
        case connected(String) // model info or response
        case failed(String)
    }
    @State private var gatewayStatus: GatewayStatus = .unknown
    @State private var pollTimer: Timer?

    var body: some View {
        Form {
            Section("Permissions") {
                permissionRow(
                    icon: "mic.fill",
                    title: "Microphone",
                    status: micStatusText,
                    granted: micStatus == .authorized,
                    action: requestMic
                )
                permissionRow(
                    icon: "waveform",
                    title: "Speech Recognition",
                    status: speechStatusText,
                    granted: speechStatus == .authorized,
                    action: requestSpeech
                )
                permissionRow(
                    icon: "accessibility",
                    title: "Accessibility (Paste)",
                    status: accessibilityGranted ? "Granted" : "Not Granted",
                    granted: accessibilityGranted,
                    action: requestAccessibility
                )

                HStack {
                    Spacer()
                    Button("Refresh Status") { refreshPermissions() }
                        .controlSize(.small)
                    Button("Open Privacy Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .controlSize(.small)
                }
            }

            Section("API Gateway") {
                TextField("API Base URL", text: $settings.apiBaseURL, prompt: Text("https://your-gateway.com/v1"))
                    .textFieldStyle(.roundedBorder)

                HStack {
                    if showingAPIKey {
                        TextField("API Key", text: $settings.apiKey, prompt: Text("sk-..."))
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("API Key", text: $settings.apiKey, prompt: Text("sk-..."))
                            .textFieldStyle(.roundedBorder)
                    }
                    Button(action: { showingAPIKey.toggle() }) {
                        Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                }

                TextField("Model", text: $settings.apiModel, prompt: Text("gpt-4"))
                    .textFieldStyle(.roundedBorder)

                Toggle("Auto-correct grammar with AI", isOn: $settings.autoSummarize)

                // Gateway connection status
                HStack {
                    switch gatewayStatus {
                    case .unknown:
                        Image(systemName: "circle.fill")
                            .foregroundStyle(.gray)
                            .font(.caption2)
                        Text("Not tested")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    case .checking:
                        ProgressView()
                            .controlSize(.mini)
                        Text("Checking connection...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    case .connected(let info):
                        Image(systemName: "circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption2)
                        Text("Connected")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text("— \(info)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    case .failed(let error):
                        Image(systemName: "circle.fill")
                            .foregroundStyle(.red)
                            .font(.caption2)
                        Text("Failed")
                            .font(.caption)
                            .foregroundStyle(.red)
                        Text("— \(error)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button("Test Connection") { testGateway() }
                        .controlSize(.small)
                        .disabled({
                            if case .checking = gatewayStatus { return true }
                            return false
                        }())
                }
            }

            Section("Slack") {
                TextField("Webhook URL", text: $settings.slackWebhookURL, prompt: Text("https://hooks.slack.com/services/..."))
                    .textFieldStyle(.roundedBorder)
            }

            Section("Language") {
                Picker("Default Language", selection: $settings.selectedLanguage) {
                    ForEach(languages, id: \.identifier) { lang in
                        Text(lang.name).tag(lang.identifier)
                    }
                }
                Toggle("Auto-detect language", isOn: $settings.autoDetectLanguage)
            }

            Section("Export") {
                Toggle("Save transcripts to file", isOn: $settings.exportToFile)
                HStack {
                    Text("~/Documents/Scriber/")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Open Folder") {
                        TranscriptExporter.openFolder()
                    }
                    .controlSize(.small)
                }
            }

            Section("General") {
                Toggle("Launch at login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { settings.launchAtLogin = $0 }
                ))
                Toggle("Sound feedback", isOn: $settings.soundFeedback)
            }

            Section("AI Identity & Instructions") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Identity")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $settings.aiIdentity)
                        .font(.system(size: 11))
                        .frame(height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.1)))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Custom Instructions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $settings.customInstructions)
                        .font(.system(size: 11))
                        .frame(height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.1)))
                    Text("Added to every AI request. E.g. \"Always use bullet points\" or \"Keep responses under 2 sentences\"")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            languages = TranscriptionService.availableLanguages
            refreshPermissions()
            if settings.isAPIConfigured {
                testGateway()
            }
            pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                DispatchQueue.main.async { refreshPermissions() }
            }
        }
        .onDisappear {
            pollTimer?.invalidate()
            pollTimer = nil
        }
    }

    // MARK: - Gateway test

    private func testGateway() {
        guard !settings.apiBaseURL.isEmpty, !settings.apiKey.isEmpty else {
            gatewayStatus = .failed("URL or key not set")
            return
        }

        gatewayStatus = .checking

        let baseURL = settings.apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let model = settings.apiModel

        // Send a minimal chat completion request to verify connectivity
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            gatewayStatus = .failed("Invalid URL")
            return
        }

        let body = ChatRequest(
            model: model,
            messages: [.init(role: "user", content: "Hi")]
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            gatewayStatus = .failed("Encoding error")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    gatewayStatus = .failed(error.localizedDescription)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    gatewayStatus = .failed("No response")
                    return
                }

                if httpResponse.statusCode == 200 {
                    // Try to extract model from response
                    var modelUsed = model
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let respModel = json["model"] as? String {
                        modelUsed = respModel
                    }
                    gatewayStatus = .connected(modelUsed)
                } else if httpResponse.statusCode == 401 {
                    gatewayStatus = .failed("Unauthorized (invalid key)")
                } else if httpResponse.statusCode == 404 {
                    gatewayStatus = .failed("Endpoint not found (check URL)")
                } else {
                    var msg = "HTTP \(httpResponse.statusCode)"
                    if let data = data, let body = String(data: data, encoding: .utf8)?.prefix(80) {
                        msg += " — \(body)"
                    }
                    gatewayStatus = .failed(msg)
                }
            }
        }.resume()
    }

    // MARK: - Permission helpers

    private func permissionRow(icon: String, title: String, status: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(granted ? .green : .orange)
            Text(title)
            Spacer()
            if granted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Grant") { action() }
                        .controlSize(.small)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var micStatusText: String {
        switch micStatus {
        case .authorized: return "Granted"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Asked"
        @unknown default: return "Unknown"
        }
    }

    private var speechStatusText: String {
        switch speechStatus {
        case .authorized: return "Granted"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Asked"
        @unknown default: return "Unknown"
        }
    }

    private func refreshPermissions() {
        micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        speechStatus = SFSpeechRecognizer.authorizationStatus()
        accessibilityGranted = AXIsProcessTrusted()
    }

    private func requestMic() {
        AVCaptureDevice.requestAccess(for: .audio) { _ in
            DispatchQueue.main.async { refreshPermissions() }
        }
    }

    private func requestSpeech() {
        SFSpeechRecognizer.requestAuthorization { _ in
            DispatchQueue.main.async { refreshPermissions() }
        }
    }

    private func requestAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { refreshPermissions() }
    }
}
