import Foundation

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    
    struct ChatMessage: Codable {
        let role: String
        let content: String
    }
}

struct ChatCompletionResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let role: String
            let content: String
        }
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL. Please check your configuration."
        case .noData:
            return "No data received from server. Please try again."
        case .decodingError:
            return "Failed to decode server response. Please try again."
        case .serverError(let message):
            return "Something went wrong. Please try again.\n\n(\(message))"
        case .networkError(let error):
            return "No internet connection. Please check your network and try again.\n\n(\(error.localizedDescription))"
        }
    }
}
