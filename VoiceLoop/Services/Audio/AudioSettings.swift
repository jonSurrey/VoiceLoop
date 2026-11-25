import Foundation
import AVFoundation

enum AudioSettings {
    static let sampleRate: Double = 44100.0
    static let channels: Int = 1
    static let formatID = kAudioFormatMPEG4AAC
    static let quality = AVAudioQuality.high
    
    static var recordingSettings: [String: Any] {
        [
            AVFormatIDKey: Int(formatID),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVEncoderAudioQualityKey: quality.rawValue
        ]
    }
}

