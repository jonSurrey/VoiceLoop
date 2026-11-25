import Foundation

protocol Transcribing {
    func transcribe(_ audioURL: URL) async throws -> String
}

