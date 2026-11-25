import Foundation

final class ChatService: ChatProtocol {
    /// Returns a canned reply so the app works without an OpenAI key or quota.
    static var isDebugMode: Bool = true
    
    private let apiClient: APIClient
    private let endpoint: String
    private let model: String
    
    init(
        apiKey: String = APIConfig.openAIAPIKey,
        endpoint: String = APIConfig.chatCompletionURL,
        model: String = APIConfig.chatModel
    ) {
        self.apiClient = APIClient(apiKey: apiKey)
        self.endpoint = endpoint
        self.model = model
    }
    
    func sendMessage(messages: [Message]) async throws -> String {
        if Self.isDebugMode {
            try await Task.sleep(nanoseconds: 500_000_000)
            return "This is a mock response for testing. Debug mode is enabled, so no actual API call is being made."
        }
        
        let apiMessages = messages.map { message in
            ChatCompletionRequest.ChatMessage(
                role: message.role.rawValue,
                content: message.content
            )
        }
        
        let requestBody = ChatCompletionRequest(
            model: model,
            messages: apiMessages
        )
        
        guard let httpBody = try? JSONEncoder().encode(requestBody) else {
            throw APIError.decodingError
        }
        
        let response: ChatCompletionResponse = try await apiClient.request(
            endpoint: endpoint,
            method: "POST",
            body: httpBody
        )
        
        guard let firstChoice = response.choices.first else {
            throw APIError.noData
        }
        
        return firstChoice.message.content
    }
    
    func sendMessage(text: String) async throws -> String {
        let message = Message(role: .user, content: text)
        return try await sendMessage(messages: [message])
    }
}
