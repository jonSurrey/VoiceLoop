import Foundation

struct APIConfig {
    static var openAIAPIKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "OpenAIAPIKey") as? String else {
            return ""
        }
        return key
    }
    
    static let chatCompletionURL = "https://api.openai.com/v1/chat/completions"
    
    static let chatModel = "gpt-4o-mini"
    
    static var isConfigured: Bool {
        !openAIAPIKey.isEmpty
    }
}
