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
        #expect(viewModel.error == nil)
    }

    @Test("Recording without microphone permission shows an error")
    func recordingWithoutPermission() {
        recorder.permission = false
        let viewModel = makeViewModel()

        viewModel.startRecording()

        #expect(viewModel.state == .error)
        #expect(viewModel.error != nil)
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
        #expect(viewModel.error != nil)
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
        #expect(viewModel.state == .idle)
    }

    @Test("Recording while the reply is spoken stops speech and keeps recording")
    func recordingWhileSpeaking() async {
        let viewModel = makeViewModel()
        synthesizer.onSpeak = { viewModel.startRecording() }
        viewModel.startRecording()
        let stopsBeforeTurn = synthesizer.stopCount

        await viewModel.stopRecording()

        #expect(synthesizer.stopCount == stopsBeforeTurn + 1)
        #expect(viewModel.state == .recording)
    }

    @Test("A failed transcription keeps the recording and Try Again transcribes it")
    func retryTranscription() async throws {
        transcriber.result = .failure(TestError())
        let viewModel = makeViewModel()
        viewModel.startRecording()
        await viewModel.stopRecording()

        let failure = try #require(viewModel.error)
        #expect(failure.retryStep == .transcribe(recorder.recordingFile))
        #expect(recorder.deletedURLs.isEmpty)

        transcriber.result = .success("Hello")
        await viewModel.retry(failure)

        #expect(transcriber.transcribedURLs == [recorder.recordingFile, recorder.recordingFile])
        #expect(viewModel.messages.map(\.role) == [.user, .assistant])
        #expect(recorder.deletedURLs == [recorder.recordingFile])
    }

    @Test("A failed reply offers Try Again, which re-sends without duplicating the user message")
    func retryReply() async throws {
        chat.result = .failure(TestError())
        let viewModel = makeViewModel()
        viewModel.startRecording()
        await viewModel.stopRecording()

        let failure = try #require(viewModel.error)
        #expect(failure.retryStep == .reply)

        chat.result = .success("Hi there")
        await viewModel.retry(failure)

        #expect(transcriber.transcribedURLs.count == 1)
        #expect(chat.receivedHistories.count == 2)
        #expect(viewModel.messages.map(\.role) == [.user, .assistant])
    }

    @Test("Dismissing an error returns to idle")
    func dismissingError() async {
        transcriber.result = .failure(TestError())
        let viewModel = makeViewModel()
        viewModel.startRecording()
        await viewModel.stopRecording()

        viewModel.dismissError()

        #expect(viewModel.state == .idle)
        #expect(viewModel.error == nil)
    }

    @Test("Try Again still works if the alert was dismissed first")
    func retryAfterDismissal() async throws {
        transcriber.result = .failure(TestError())
        let viewModel = makeViewModel()
        viewModel.startRecording()
        await viewModel.stopRecording()
        let failure = try #require(viewModel.error)

        viewModel.dismissError()
        transcriber.result = .success("Hello")
        await viewModel.retry(failure)

        #expect(viewModel.messages.map(\.role) == [.user, .assistant])
    }

    @Test("A new recording deletes the recording kept from a failed transcription")
    func newRecordingDiscardsKeptRecording() async {
        transcriber.result = .failure(TestError())
        let viewModel = makeViewModel()
        viewModel.startRecording()
        await viewModel.stopRecording()
        viewModel.dismissError()

        viewModel.startRecording()

        #expect(recorder.deletedURLs == [recorder.recordingFile])
    }

    @Test("An interruption stops and deletes the recording and shows an error")
    func interruption() {
        let viewModel = makeViewModel()
        viewModel.startRecording()

        recorder.onInterruption?()

        #expect(viewModel.state == .error)
        #expect(viewModel.error != nil)
        #expect(recorder.deletedURLs == [recorder.recordingFile])
    }

    @Test("Stopping speech returns to idle and the end of speech changes nothing")
    func stoppingSpeech() async {
        let viewModel = makeViewModel()
        synthesizer.onSpeak = { viewModel.stopSpeaking() }
        viewModel.startRecording()
        let stopsBeforeTurn = synthesizer.stopCount

        await viewModel.stopRecording()

        #expect(synthesizer.stopCount == stopsBeforeTurn + 1)
        #expect(viewModel.state == .idle)
    }

    @Test("Clearing the conversation removes messages and stops speech")
    func clearingConversation() async {
        let viewModel = makeViewModel()
        viewModel.startRecording()
        await viewModel.stopRecording()

        let stopsBeforeClearing = synthesizer.stopCount

        viewModel.clearConversation()

        #expect(viewModel.messages.isEmpty)
        #expect(viewModel.state == .idle)
        #expect(synthesizer.stopCount == stopsBeforeClearing + 1)
    }
}
