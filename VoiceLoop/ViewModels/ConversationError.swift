import Foundation

struct ConversationError: Equatable {
    enum RetryStep: Equatable {
        case transcribe(URL)
        case reply
    }

    enum Recovery: Equatable {
        case retry(RetryStep)
        case openSettings
    }

    let message: String
    let recovery: Recovery?
}

nonisolated protocol RetryableError: Error {
    var isRetryable: Bool { get }
}
