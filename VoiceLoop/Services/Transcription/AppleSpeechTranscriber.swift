import Foundation
import os
import Speech

final class AppleSpeechTranscriber: Transcribing {
    private let recognizer = SFSpeechRecognizer()

    func transcribe(_ audioURL: URL) async throws -> String {
        guard await Self.requestAuthorization() else {
            throw TranscriptionError.notAuthorized
        }
        guard let recognizer, recognizer.isAvailable else {
            throw TranscriptionError.unavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        let transcript = try await Self.recognize(request, with: recognizer)
        guard !transcript.isEmpty else {
            throw TranscriptionError.recognitionFailed
        }
        return transcript
    }

    private nonisolated static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    /// The recognizer can call back more than once; the lock hands the continuation out to the first final result or error.
    private nonisolated static func recognize(
        _ request: SFSpeechURLRecognitionRequest,
        with recognizer: SFSpeechRecognizer
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let pending = OSAllocatedUnfairLock<CheckedContinuation<String, Error>?>(initialState: continuation)
            recognizer.recognitionTask(with: request) { result, error in
                let outcome: Result<String, Error>
                if error != nil {
                    outcome = .failure(TranscriptionError.recognitionFailed)
                } else if let result, result.isFinal {
                    outcome = .success(result.bestTranscription.formattedString)
                } else {
                    return
                }
                pending.withLock { $0.take() }?.resume(with: outcome)
            }
        }
    }
}
