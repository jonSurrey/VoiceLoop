import Foundation

struct ConversationError: Equatable {
    enum RetryStep: Equatable {
        case transcribe(URL)
        case reply
    }

    let message: String
    let retryStep: RetryStep?
}
