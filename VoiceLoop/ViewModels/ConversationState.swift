import Foundation

enum ConversationState {
    case idle
    case recording
    case transcribing
    case generating
    case speaking
    case error
    
    var canStartRecording: Bool {
        self == .idle || self == .speaking
    }
    
    var canStopRecording: Bool {
        self == .recording
    }
    
    var isProcessing: Bool {
        switch self {
        case .transcribing, .generating, .speaking:
            return true
        default:
            return false
        }
    }
}

