import Foundation

protocol ChatCompleting {
    func reply(to messages: [Message]) async throws -> String
}

