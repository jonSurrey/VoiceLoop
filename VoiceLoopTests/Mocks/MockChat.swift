@testable import VoiceLoop

final class MockChat: ChatCompleting {
    var result: Result<String, Error> = .success("Hi there")
    private(set) var receivedHistories: [[Message]] = []

    func reply(to messages: [Message]) async throws -> String {
        receivedHistories.append(messages)
        return try result.get()
    }
}
