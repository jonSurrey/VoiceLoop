import Foundation
import Speech

final class TranscriptionService: TranscriptionProtocol {
    
    // MARK: - Properties
    
    private let recognizer: SFSpeechRecognizer?
    
    // MARK: - Initialization
    
    init(locale: Locale = Locale(identifier: "en-US")) {
        self.recognizer = SFSpeechRecognizer(locale: locale)
    }
    
    // MARK: - Transcription
    
    func transcribe(audioURL: URL) async throws -> String {
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            throw APIError.serverError("Audio file not found")
        }
        
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: audioURL.path),
              let fileSize = attributes[.size] as? Int64, fileSize > 0 else {
            throw APIError.serverError("Audio file is empty")
        }
        
        guard await requestPermission() else {
            throw APIError.serverError("Speech recognition permission denied. Please enable it in Settings.")
        }
        
        guard let recognizer = recognizer else {
            throw APIError.serverError("Speech recognition is not supported for this language.")
        }
        
        guard recognizer.isAvailable else {
            throw APIError.serverError("Speech recognition is temporarily unavailable. Please try again.")
        }
        
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: APIError.networkError(error))
                    return
                }
                
                guard let result = result else {
                    continuation.resume(throwing: APIError.serverError("No transcription result"))
                    return
                }
                
                if result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
    
    // MARK: - Permission
    
    private func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}


