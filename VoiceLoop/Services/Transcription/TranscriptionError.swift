import Foundation

enum TranscriptionError: LocalizedError {
    case notAuthorized
    case unavailable
    case recognitionFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            "Speech recognition is turned off for VoiceLoop. Turn it on in Settings."
        case .unavailable:
            "Speech recognition isn't available for your language right now."
        case .recognitionFailed:
            "Couldn't understand the recording. Try again."
        }
    }
}
