import SwiftUI

@main
struct VoiceLoopApp: App {
    @StateObject private var viewModel = ConversationViewModel(
        audioRecordingService: AudioRecordingService(),
        transcriptionService: TranscriptionService(),
        chatService: ChatService(),
        ttsService: TextToSpeechService()
    )

    var body: some Scene {
        WindowGroup {
            ConversationView(viewModel: viewModel)
        }
    }
}
