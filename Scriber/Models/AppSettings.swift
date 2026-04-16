import SwiftUI
import ServiceManagement

enum MessageTone: String, CaseIterable {
    case casual = "casual"
    case professional = "professional"
    case prompt = "prompt"

    var label: String {
        switch self {
        case .casual: return "Casual"
        case .professional: return "Professional"
        case .prompt: return "Prompt"
        }
    }

    var icon: String {
        switch self {
        case .casual: return "face.smiling"
        case .professional: return "briefcase"
        case .prompt: return "sparkles"
        }
    }
}

final class AppSettings: ObservableObject {
    @AppStorage("apiBaseURL") var apiBaseURL: String = ""
    @AppStorage("apiKey") var apiKey: String = ""
    @AppStorage("apiModel") var apiModel: String = "gpt-4"
    @AppStorage("slackWebhookURL") var slackWebhookURL: String = ""
    @AppStorage("selectedLanguage") var selectedLanguage: String = "en-US"
    @AppStorage("autoSummarize") var autoSummarize: Bool = true
    @AppStorage("selectedTone") var selectedTone: String = MessageTone.professional.rawValue
    @AppStorage("autoDetectLanguage") var autoDetectLanguage: Bool = true
    @AppStorage("exportToFile") var exportToFile: Bool = true
    @AppStorage("soundFeedback") var soundFeedback: Bool = true
    @AppStorage("aiIdentity") var aiIdentity: String = "You are Scriber, a voice-to-text assistant built into a macOS app. You help users turn spoken words into polished, ready-to-send messages. You can rewrite in casual, professional, or prompt format. You support 50+ languages. When asked who you are or what you can do, introduce yourself as Scriber and briefly list your capabilities."
    @AppStorage("customInstructions") var customInstructions: String = ""

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            objectWillChange.send()
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                Log.write("Launch at login error: \(error)")
            }
        }
    }

    var tone: MessageTone {
        get { MessageTone(rawValue: selectedTone) ?? .professional }
        set { selectedTone = newValue.rawValue }
    }

    var isAPIConfigured: Bool {
        !apiBaseURL.isEmpty && !apiKey.isEmpty
    }

    var isSlackConfigured: Bool {
        !slackWebhookURL.isEmpty
    }

    init() {
        if let keychainKey = KeychainHelper.load(key: "apiKey"), !keychainKey.isEmpty {
            if apiKey.isEmpty {
                apiKey = keychainKey
            }
            KeychainHelper.delete(key: "apiKey")
        }
    }
}
