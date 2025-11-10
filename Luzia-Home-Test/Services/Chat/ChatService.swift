import Foundation

final class ChatService: ChatProtocol {
    
    // MARK: - Debug
    
    static var isDebugMode: Bool = true
    
    // MARK: - Properties
    
    private let apiClient: APIClient
    private let endpoint: String
    private let model: String
    
    // MARK: - Initialization
    
    init(
        apiKey: String = APIConfig.openAIAPIKey,
        endpoint: String = APIConfig.chatCompletionURL,
        model: String = APIConfig.chatModel
    ) {
        self.apiClient = APIClient(apiKey: apiKey)
        self.endpoint = endpoint
        self.model = model
    }
    
    // MARK: - Chat Completion
    
    func sendMessage(messages: [Message]) async throws -> String {
        // Return mock response in debug mode
        //
        // We use this mock because the API is returning 
        // error 429: "You exceeded your current quota, please check your plan and billing details".
        if Self.isDebugMode {
            try await Task.sleep(nanoseconds: 500_000_000) // Simulate 0.5s delay
            return "This is a mock response for testing. Debug mode is enabled, so no actual API call is being made."
        }
        
        // Prepare request body
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


