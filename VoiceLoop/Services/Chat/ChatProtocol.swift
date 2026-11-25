import Foundation

protocol ChatProtocol {
    func sendMessage(messages: [Message]) async throws -> String
    func sendMessage(text: String) async throws -> String
}

