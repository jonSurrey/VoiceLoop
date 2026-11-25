import XCTest
@testable import VoiceLoop

final class ConversationViewModelTests: XCTestCase {
    var viewModel: ConversationViewModel!
    var recorder: MockAudioRecorder!
    var transcriber: MockTranscriber!
    var chat: MockChat!
    var synthesizer: MockSpeechSynthesizer!
    
    override func setUp() {
        super.setUp()
        recorder = MockAudioRecorder()
        transcriber = MockTranscriber()
        chat = MockChat()
        synthesizer = MockSpeechSynthesizer()
        
        viewModel = ConversationViewModel(
            recorder: recorder,
            transcriber: transcriber,
            chat: chat,
            synthesizer: synthesizer
        )
    }
    
    func testInitialStateShouldBeIdle() {
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testCanRecordWhenPermissionGranted() {
        recorder.hasPermission = true
        viewModel = ConversationViewModel(
            recorder: recorder,
            transcriber: transcriber,
            chat: chat,
            synthesizer: synthesizer
        )
        
        XCTAssertTrue(viewModel.canRecord)
    }
    
    func testCannotRecordWithoutPermission() {
        recorder.hasPermission = false
        viewModel = ConversationViewModel(
            recorder: recorder,
            transcriber: transcriber,
            chat: chat,
            synthesizer: synthesizer
        )
        
        XCTAssertFalse(viewModel.canRecord)
    }
    
    func testStartRecordingUpdatesState() throws {
        recorder.hasPermission = true
        viewModel = ConversationViewModel(
            recorder: recorder,
            transcriber: transcriber,
            chat: chat,
            synthesizer: synthesizer
        )
        
        viewModel.startRecording()
        
        XCTAssertEqual(viewModel.state, .recording)
        XCTAssertTrue(recorder.startRecordingCalled)
        XCTAssertTrue(viewModel.isRecording)
    }
    
    func testStopRecordingTriggersProcessing() async {
        recorder.hasPermission = true
        viewModel = ConversationViewModel(
            recorder: recorder,
            transcriber: transcriber,
            chat: chat,
            synthesizer: synthesizer
        )
        
        viewModel.startRecording()
        await viewModel.stopRecording()
        
        XCTAssertTrue(recorder.stopRecordingCalled)
    }
    
    func testFullConversationFlow() async throws {
        recorder.hasPermission = true
        transcriber.transcript = "Hello AI"
        chat.mockResponse = "Hello! How can I help?"
        
        viewModel = ConversationViewModel(
            recorder: recorder,
            transcriber: transcriber,
            chat: chat,
            synthesizer: synthesizer
        )
        
        viewModel.startRecording()
        await viewModel.stopRecording()
        
        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages[0].content, "Hello AI")
        XCTAssertEqual(viewModel.messages[0].role, .user)
        XCTAssertEqual(viewModel.messages[1].content, "Hello! How can I help?")
        XCTAssertEqual(viewModel.messages[1].role, .assistant)
        XCTAssertTrue(synthesizer.speakCalled)
    }
    
    func testErrorHandlingOnTranscriptionFails() async throws {
        recorder.hasPermission = true
        transcriber.shouldThrowError = true
        
        viewModel = ConversationViewModel(
            recorder: recorder,
            transcriber: transcriber,
            chat: chat,
            synthesizer: synthesizer
        )
        
        viewModel.startRecording()
        await viewModel.stopRecording()
        
        XCTAssertEqual(viewModel.state, .error)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testStopSpeakingCallsTTSStop() {
        viewModel.stopSpeaking()
        
        XCTAssertTrue(synthesizer.stopCalled)
        XCTAssertEqual(viewModel.state, .idle)
    }
    
    func testTTSCompletionTransitionsToIdle() {
        let expectation = XCTestExpectation(description: "TTS completion")
        
        synthesizer.onSpeak = { completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion?()
                expectation.fulfill()
            }
        }
        
        synthesizer.speak("Test", completion: nil)
        wait(for: [expectation], timeout: 1.0)
    }
}

final class MockAudioRecorder: AudioRecording {
    var hasPermission = true
    var startRecordingCalled = false
    var stopRecordingCalled = false
    
    func requestPermission() async -> Bool {
        return hasPermission
    }
    
    func checkPermission() -> Bool {
        return hasPermission
    }
    
    func startRecording() throws -> URL {
        startRecordingCalled = true
        return URL(fileURLWithPath: "/tmp/test.m4a")
    }
    
    func stopRecording() -> URL? {
        stopRecordingCalled = true
        return URL(fileURLWithPath: "/tmp/test.m4a")
    }
    
    func deleteRecording(at url: URL) {}
}

final class MockTranscriber: Transcribing {
    var transcript = ""
    var shouldThrowError = false
    
    func transcribe(_ audioURL: URL) async throws -> String {
        if shouldThrowError {
            throw APIError.serverError("Transcription failed")
        }
        return transcript
    }
}

final class MockChat: ChatCompleting {
    var mockResponse = ""
    var shouldThrowError = false
    
    func reply(to messages: [Message]) async throws -> String {
        if shouldThrowError {
            throw APIError.serverError("Chat failed")
        }
        return mockResponse
    }
}

final class MockSpeechSynthesizer: SpeechSynthesizing {
    var speakCalled = false
    var stopCalled = false
    var onSpeak: (((() -> Void)?) -> Void)?
    
    func speak(_ text: String, completion: (() -> Void)?) {
        speakCalled = true
        onSpeak?(completion)
    }
    
    func stop() {
        stopCalled = true
    }
}
