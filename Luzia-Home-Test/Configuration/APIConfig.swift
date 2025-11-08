import Foundation

struct APIConfig {
    
    // MARK: - API Keys
    
    static var openAIAPIKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "OpenAIAPIKey") as? String else {
            return ""
        }
        return key
    }
    
    // MARK: - Endpoint
    
    static let chatCompletionURL = "https://api.openai.com/v1/chat/completions"
    
    // MARK: - Model
    
    static let chatModel = "gpt-4o-mini"
    
    // MARK: - Validation
    
    static var isConfigured: Bool {
        !openAIAPIKey.isEmpty
    }
}
