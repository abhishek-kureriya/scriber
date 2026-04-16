import Foundation

final class GrammarService {

    struct APIConfig {
        let baseURL: String
        let apiKey: String
        let model: String
    }

    private static let baseRules = """
        You receive raw speech-to-text that may be rough, fragmented, or shorthand. \
        Your job is to turn it into a ready-to-send message. \
        Understand the speaker's intent and write it as a real person would type it. \
        Stay faithful to what they said — don't add unrelated information. \
        But DO complete the thought naturally. \
        "moving meeting to tomorrow tell the team" → "Hey team, the meeting has been moved to tomorrow." \
        "sick child not coming in" → "My child is sick, so I won't be coming in today." \
        "deployed fix monitoring now" → "Deployed the fix, monitoring it now." \
        Output ONLY the final message. No quotes, no labels, no commentary.
        """

    private static let tonePrompts: [MessageTone: String] = [
        .casual: """
            Turn this speech into a casual, friendly message. \
            Use contractions, keep it short and conversational. \
            Like texting a coworker you're friendly with. \
            \(baseRules)
            """,
        .professional: """
            Turn this speech into a clean, natural, professional message. \
            Friendly but polished — how you'd write a Slack message to your team. \
            \(baseRules)
            """,
        .prompt: """
            Turn this speech into a well-structured AI prompt. \
            The user is speaking rough ideas, requirements, or instructions. \
            Your job is to format it as a clear, detailed prompt that can be fed to an AI (like Claude or GPT). \
            Structure it with: clear objective, requirements as bullet points, constraints if mentioned, expected output format. \
            Use imperative tone ("Create...", "Write...", "Build..."). \
            Make it specific and actionable. \
            Do NOT wrap it in quotes or add labels like "Prompt:". \
            Output ONLY the formatted prompt, nothing else.
            """
    ]

    func correct(text: String, config: APIConfig, tone: MessageTone = .professional, identity: String = "", customInstructions: String = "") async throws -> String {
        guard !config.baseURL.isEmpty, !config.apiKey.isEmpty else {
            return text
        }

        let baseURL = config.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            return text
        }

        let tonePrompt = GrammarService.tonePrompts[tone] ?? GrammarService.tonePrompts[.professional]!

        // Assemble: identity + custom instructions + tone prompt
        var systemParts: [String] = []
        if !identity.isEmpty { systemParts.append(identity) }
        if !customInstructions.isEmpty { systemParts.append("Custom instructions: \(customInstructions)") }
        systemParts.append(tonePrompt)
        let systemPrompt = systemParts.joined(separator: "\n\n")

        let request = ChatRequest(
            model: config.model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: text)
            ]
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        urlRequest.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return text
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        return chatResponse.choices.first?.message.content ?? text
    }
}
