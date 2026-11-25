@testable import VoiceLoop

final class MockSpeechSynthesizer: SpeechSynthesizing {
    private(set) var spokenTexts: [String] = []
    private(set) var stopCount = 0

    func speak(_ text: String, completion: (() -> Void)?) {
        spokenTexts.append(text)
    }

    func stop() {
        stopCount += 1
    }
}
