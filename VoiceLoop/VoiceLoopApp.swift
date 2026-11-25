import SwiftUI

@main
struct VoiceLoopApp: App {
    @State private var viewModel = ConversationViewModel(
        recorder: AudioRecorder(),
        transcriber: AppleSpeechTranscriber(),
        chat: OpenAIChatService(apiClient: APIClient(apiKey: APIConfig.openAIAPIKey)),
        synthesizer: SpeechSynthesizer()
    )

    var body: some Scene {
        WindowGroup {
            ConversationView(viewModel: viewModel)
        }
    }
}
