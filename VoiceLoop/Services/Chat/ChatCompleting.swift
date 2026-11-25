import Foundation

protocol ChatCompleting {
    func reply(to messages: [Message]) async throws -> String
    func sendMessage(text: String) async throws -> String
}

