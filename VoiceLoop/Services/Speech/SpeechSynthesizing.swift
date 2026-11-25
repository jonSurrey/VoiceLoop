protocol SpeechSynthesizing {
    func speak(_ text: String) async
    func stop()
}
