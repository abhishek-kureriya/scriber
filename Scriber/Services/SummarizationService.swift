import Foundation

final class SummarizationService {

    struct APIConfig: Sendable {
        let baseURL: String
        let apiKey: String
        let model: String
    }

    func summarize(transcript: String, config: APIConfig) async throws -> String {
        guard !config.baseURL.isEmpty, !config.apiKey.isEmpty else {
            throw SummarizationError.notConfigured
        }

        let baseURL = config.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw SummarizationError.invalidURL
        }

        let request = ChatRequest(
            model: config.model,
            messages: [
                .init(role: "system", content: """
                    You are a meeting notes assistant. Summarize the following meeting transcript into concise, \
                    well-structured notes. Include:
                    - Key discussion points
                    - Decisions made
                    - Action items (with owners if mentioned)
                    Keep it brief and actionable.
                    """),
                .init(role: "user", content: transcript)
            ]
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        urlRequest.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SummarizationError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SummarizationError.apiError(statusCode: httpResponse.statusCode, message: body)
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)

        guard let content = chatResponse.choices.first?.message.content else {
            throw SummarizationError.emptyResponse
        }

        return content
    }
}

enum SummarizationError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case emptyResponse
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "API is not configured. Please set your API base URL and key in Settings."
        case .invalidURL:
            return "Invalid API URL. Please check your API base URL in Settings."
        case .invalidResponse:
            return "Received an invalid response from the API."
        case .emptyResponse:
            return "The API returned an empty response."
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        }
    }
}
