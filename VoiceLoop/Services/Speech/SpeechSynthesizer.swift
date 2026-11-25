import AVFoundation

final class SpeechSynthesizer: NSObject, SpeechSynthesizing {
    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    private var finishedSpeaking: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        synthesizer.usesApplicationAudioSession = false
        synthesizer.delegate = self
    }

    func speak(_ text: String) async {
        stop()
        let utterance = AVSpeechUtterance(string: text)
        await withCheckedContinuation { continuation in
            currentUtterance = utterance
            finishedSpeaking = continuation
            synthesizer.speak(utterance)
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        finish()
    }

    private func finish(_ utteranceID: ObjectIdentifier) {
        guard let currentUtterance, ObjectIdentifier(currentUtterance) == utteranceID else {
            return
        }
        finish()
    }

    private func finish() {
        currentUtterance = nil
        finishedSpeaking?.resume()
        finishedSpeaking = nil
    }
}

extension SpeechSynthesizer: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let utteranceID = ObjectIdentifier(utterance)
        Task { @MainActor in
            self.finish(utteranceID)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let utteranceID = ObjectIdentifier(utterance)
        Task { @MainActor in
            self.finish(utteranceID)
        }
    }
}
