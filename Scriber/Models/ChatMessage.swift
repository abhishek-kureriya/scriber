import Foundation

struct ChatRequest: Codable {
    let model: String
    let messages: [Message]

    struct Message: Codable {
        let role: String
        let content: String
    }
}

struct ChatResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: ResponseMessage
    }

    struct ResponseMessage: Codable {
        let content: String
    }
}
