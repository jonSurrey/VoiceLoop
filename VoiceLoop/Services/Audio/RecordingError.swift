import Foundation

enum RecordingError: LocalizedError {
    case failedToStart

    var errorDescription: String? {
        switch self {
        case .failedToStart:
            "Couldn't start recording. Please try again."
        }
    }
}
