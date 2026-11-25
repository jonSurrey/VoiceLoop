import Foundation
import Testing
@testable import VoiceLoop

@Suite("Conversation view model")
struct ConversationViewModelTests {
    let recorder = MockAudioRecorder()
    let transcriber = MockTranscriber()
    let chat = MockChat()
    let synthesizer = MockSpeechSynthesizer()

    private func makeViewModel() -> ConversationViewModel {
        ConversationViewModel(recorder: recorder, transcriber: transcriber, chat: chat, synthesizer: synthesizer)
    }

    @Test("Starts idle with no messages")
    func startsIdle() {
        let viewModel = makeViewModel()

        #expect(viewModel.state == .idle)
        #expect(viewModel.messages.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Recording without microphone permission shows an error")
    func recordingWithoutPermission() {
        recorder.permission = false
        let viewModel = makeViewModel()

        viewModel.startRecording()

        #expect(viewModel.state == .error)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("Denying microphone permission shows an error")
    func denyingPermission() async {
        recorder.permission = false
        let viewModel = makeViewModel()

        await viewModel.requestMicrophonePermission()

        #expect(!viewModel.hasMicrophonePermission)
        #expect(viewModel.state == .error)
    }

    @Test("Starting a recording moves to recording")
    func startingRecording() {
        let viewModel = makeViewModel()

        viewModel.startRecording()

        #expect(viewModel.state == .recording)
        #expect(viewModel.isRecording)
    }

    @Test("A recorder that fails to start shows an error")
    func recorderFailsToStart() {
        recorder.startError = TestError()
        let viewModel = makeViewModel()

        viewModel.startRecording()

        #expect(viewModel.state == .error)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("A stop that returns no recording shows an error")
    func stopWithoutRecording() async {
        let viewModel = makeViewModel()
        viewModel.startRecording()
        recorder.stopResult = nil

        await viewModel.stopRecording()

        #expect(viewModel.state == .error)
        #expect(transcriber.transcribedURLs.isEmpty)
    }

    @Test("A full turn adds both messages and speaks the reply")
    func fullTurn() async {
        transcriber.result = .success("Hello AI")
        chat.result = .success("Hello! How can I help?")
        let viewModel = makeViewModel()

        viewModel.startRecording()
        await viewModel.stopRecording()

        #expect(viewModel.messages.map(\.role) == [.user, .assistant])
        #expect(viewModel.messages.map(\.content) == ["Hello AI", "Hello! How can I help?"])
        #expect(synthesizer.spokenTexts == ["Hello! How can I help?"])
    }

    @Test("A failed transcription keeps the recording and Try Again transcribes it")
    func retryTranscription() async {
        transcriber.result = .failure(TestError())
        let viewModel = makeViewModel()
        viewModel.startRecording()
        await viewModel.stopRecording()

        #expect(viewModel.state == .error)
        #expect(viewModel.canRetry)
        #expect(recorder.deletedURLs.isEmpty)

        transcriber.result = .success("Hello")
        await viewModel.retry()

        #expect(transcriber.transcribedURLs == [recorder.recordingFile, recorder.recordingFile])
        #expect(viewModel.messages.map(\.role) == [.user, .assistant])
        #expect(recorder.deletedURLs == [recorder.recordingFile])
    }

    @Test("A failed reply offers Try Again, which re-sends without duplicating the user message")
    func retryReply() async {
        chat.result = .failure(TestError())
        let viewModel = makeViewModel()
        viewModel.startRecording()
        await viewModel.stopRecording()

        #expect(viewModel.state == .error)
        #expect(viewModel.canRetry)

        chat.result = .success("Hi there")
        await viewModel.retry()

        #expect(transcriber.transcribedURLs.count == 1)
        #expect(chat.receivedHistories.count == 2)
        #expect(viewModel.messages.map(\.role) == [.user, .assistant])
    }

    @Test("Dismissing an error deletes the kept recording and returns to idle")
    func dismissingError() async {
        transcriber.result = .failure(TestError())
        let viewModel = makeViewModel()
        viewModel.startRecording()
        await viewModel.stopRecording()

        viewModel.dismissError()

        #expect(viewModel.state == .idle)
        #expect(!viewModel.canRetry)
        #expect(recorder.deletedURLs == [recorder.recordingFile])
    }

    @Test("An interruption stops and deletes the recording and shows an error")
    func interruption() {
        let viewModel = makeViewModel()
        viewModel.startRecording()

        recorder.onInterruption?()

        #expect(viewModel.state == .error)
        #expect(viewModel.errorMessage != nil)
        #expect(recorder.deletedURLs == [recorder.recordingFile])
    }

    @Test("Stopping speech stops the synthesizer and returns to idle")
    func stoppingSpeech() {
        let viewModel = makeViewModel()

        viewModel.stopSpeaking()

        #expect(synthesizer.stopCount == 1)
        #expect(viewModel.state == .idle)
    }

    @Test("Clearing the conversation removes messages and stops speech")
    func clearingConversation() async {
        let viewModel = makeViewModel()
        viewModel.startRecording()
        await viewModel.stopRecording()

        viewModel.clearConversation()

        #expect(viewModel.messages.isEmpty)
        #expect(viewModel.state == .idle)
        #expect(synthesizer.stopCount == 1)
    }
}
