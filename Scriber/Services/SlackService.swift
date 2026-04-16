import Foundation
import AppKit

final class SlackService {

    func send(text: String, webhookURL: String) async throws {
        guard let url = URL(string: webhookURL) else {
            throw SlackError.invalidWebhookURL
        }

        let payload = ["text": text]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 15

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SlackError.sendFailed
        }
    }

    static func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

enum SlackError: LocalizedError {
    case invalidWebhookURL
    case sendFailed

    var errorDescription: String? {
        switch self {
        case .invalidWebhookURL:
            return "Invalid Slack webhook URL. Please check Settings."
        case .sendFailed:
            return "Failed to send message to Slack."
        }
    }
}
