import Foundation

protocol SpeechSynthesizing {
    func speak(_ text: String, completion: (() -> Void)?)
    func stop()
}
