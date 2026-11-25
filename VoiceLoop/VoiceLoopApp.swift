import SwiftUI

@main
struct VoiceLoopApp: App {
    @State private var viewModel = ConversationViewModel(
        recorder: AudioRecorder(),
        transcriber: AppleSpeechTranscriber(),
        chat: OpenAIChatService(),
        synthesizer: SpeechSynthesizer()
    )

    var body: some Scene {
        WindowGroup {
            ConversationView(viewModel: viewModel)
        }
    }
}
