import Foundation

enum APIConfig {
    static let openAIAPIKey = Bundle.main.object(forInfoDictionaryKey: "OpenAIAPIKey") as? String ?? ""
    static let chatCompletionURL = "https://api.openai.com/v1/chat/completions"
    static let chatModel = "gpt-4o-mini"
}
