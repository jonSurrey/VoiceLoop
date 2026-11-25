import Foundation

enum APIError: LocalizedError, Equatable {
    case missingAPIKey
    case invalidURL
    case invalidRequest
    case network
    case invalidResponse
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "Add your OpenAI API key to chat with the AI."
        case .invalidURL:
            "The AI service address is invalid."
        case .invalidRequest:
            "Your message couldn't be sent."
        case .network:
            "Couldn't reach the AI service. Check your connection and try again."
        case .invalidResponse:
            "The AI service sent an unexpected reply. Try again."
        case .server(statusCode: HTTPStatus.unauthorized):
            "The OpenAI API key was rejected."
        case .server(statusCode: HTTPStatus.tooManyRequests):
            "The AI service is busy or out of quota. Try again later."
        case .server:
            "The AI service had a problem. Try again."
        }
    }
}

enum HTTPStatus {
    static let success = 200..<300
    static let unauthorized = 401
    static let tooManyRequests = 429
}
