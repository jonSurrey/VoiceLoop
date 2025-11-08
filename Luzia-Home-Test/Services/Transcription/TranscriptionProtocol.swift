import Foundation

protocol TranscriptionProtocol {
    func transcribe(audioURL: URL) async throws -> String
}

