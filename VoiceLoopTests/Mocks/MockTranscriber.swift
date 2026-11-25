import Foundation
@testable import VoiceLoop

final class MockTranscriber: Transcribing {
    var result: Result<String, Error> = .success("Hello")
    private(set) var transcribedURLs: [URL] = []

    func transcribe(_ audioURL: URL) async throws -> String {
        transcribedURLs.append(audioURL)
        return try result.get()
    }
}
