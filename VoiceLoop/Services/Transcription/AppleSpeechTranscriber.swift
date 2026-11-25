import Foundation
import Speech

final class AppleSpeechTranscriber: Transcribing {
    private let recognizer: SFSpeechRecognizer?
    
    init(locale: Locale = Locale(identifier: "en-US")) {
        self.recognizer = SFSpeechRecognizer(locale: locale)
    }
    
    func transcribe(_ audioURL: URL) async throws -> String {
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            throw TranscriptionError.recognitionFailed
        }
        
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: audioURL.path),
              let fileSize = attributes[.size] as? Int64, fileSize > 0 else {
            throw TranscriptionError.recognitionFailed
        }
        
        guard await requestPermission() else {
            throw TranscriptionError.notAuthorized
        }
        
        guard let recognizer = recognizer else {
            throw TranscriptionError.unavailable
        }
        
        guard recognizer.isAvailable else {
            throw TranscriptionError.unavailable
        }
        
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if error != nil {
                    continuation.resume(throwing: TranscriptionError.recognitionFailed)
                    return
                }
                
                guard let result = result else {
                    continuation.resume(throwing: TranscriptionError.recognitionFailed)
                    return
                }
                
                if result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
    
    private func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}
