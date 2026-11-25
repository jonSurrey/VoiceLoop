import Foundation

final class OpenAIChatService: ChatCompleting {
    /// Returns a canned reply so the app works without an OpenAI key or quota.
    static var isDebugMode: Bool = true
    private static let debugReply = "This is a mock response for testing. Debug mode is enabled, so no actual API call is being made."
    private static let debugReplyDelay: Duration = .milliseconds(500)

    private let apiClient: APIClient
    private let endpoint: String
    private let model: String

    init(apiClient: APIClient, endpoint: String = APIConfig.chatCompletionURL, model: String = APIConfig.chatModel) {
        self.apiClient = apiClient
        self.endpoint = endpoint
        self.model = model
    }

    func reply(to messages: [Message]) async throws -> String {
        if Self.isDebugMode {
            try await Task.sleep(for: Self.debugReplyDelay)
            return Self.debugReply
        }

        let request = ChatCompletionRequest(model: model, messages: messages)
        let response: ChatCompletionResponse = try await apiClient.post(request, to: endpoint)
        guard let reply = response.choices.first?.message.content else {
            throw APIError.invalidResponse
        }
        return reply
    }
}
