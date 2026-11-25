import Foundation
import AVFoundation

@MainActor
final class TextToSpeechService: NSObject, TextToSpeechProtocol {
    
    // MARK: - Properties
    
    private let synthesizer: AVSpeechSynthesizer
    private var onComplete: (() -> Void)?
    
    // MARK: - Initialization
    
    override init() {
        self.synthesizer = AVSpeechSynthesizer()
        super.init()
        self.synthesizer.delegate = self
    }
    
    // MARK: - Speech Control
    
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        if synthesizer.isSpeaking {
            stop()
        }
        
        self.onComplete = completion
        let utterance = AVSpeechUtterance(string: text)
        
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate // Normal speed
        utterance.pitchMultiplier = 1.0 // Normal pitch
        utterance.volume = 1.0 // Full volume
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        synthesizer.speak(utterance)
    }
    
    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
        }
    }
    
    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }
    
    func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
            onComplete = nil
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onComplete?()
        onComplete = nil
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onComplete = nil
    }
}


