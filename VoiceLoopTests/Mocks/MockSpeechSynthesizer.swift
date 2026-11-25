@testable import VoiceLoop

final class MockSpeechSynthesizer: SpeechSynthesizing {
    var onSpeak: (() -> Void)?
    private(set) var spokenTexts: [String] = []
    private(set) var stopCount = 0

    func speak(_ text: String) async {
        spokenTexts.append(text)
        onSpeak?()
    }

    func stop() {
        stopCount += 1
    }
}
