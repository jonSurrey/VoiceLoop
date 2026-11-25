import Foundation

struct ChatCompletionRequest: Encodable, Equatable {
    struct ChatMessage: Encodable, Equatable {
        let role: String
        let content: String
    }

    let model: String
    let messages: [ChatMessage]

    init(model: String, messages: [Message]) {
        self.model = model
        self.messages = messages.map { ChatMessage(role: $0.role.rawValue, content: $0.content) }
    }
}

struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        let message: ChatMessage
    }

    struct ChatMessage: Decodable {
        let content: String?
    }

    let choices: [Choice]
}
