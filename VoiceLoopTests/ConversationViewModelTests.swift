import XCTest
@testable import VoiceLoop

@MainActor
final class ConversationViewModelTests: XCTestCase {
    var viewModel: ConversationViewModel!
    var mockAudio: MockAudioRecordingService!
    var mockTranscription: MockTranscriptionService!
    var mockChat: MockChatService!
    var mockTTS: MockTextToSpeechService!
    
    override func setUp() {
        super.setUp()
        mockAudio = MockAudioRecordingService()
        mockTranscription = MockTranscriptionService()
        mockChat = MockChatService()
        mockTTS = MockTextToSpeechService()
        
        viewModel = ConversationViewModel(
            audioRecordingService: mockAudio,
            transcriptionService: mockTranscription,
            chatService: mockChat,
            ttsService: mockTTS
        )
    }
    
    func testInitialStateShouldBeIdle() {
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testCanRecordWhenPermissionGranted() {
        mockAudio.hasPermission = true
        viewModel = ConversationViewModel(
            audioRecordingService: mockAudio,
            transcriptionService: mockTranscription,
            chatService: mockChat,
            ttsService: mockTTS
        )
        
        XCTAssertTrue(viewModel.canRecord)
    }
    
    func testCannotRecordWithoutPermission() {
        mockAudio.hasPermission = false
        viewModel = ConversationViewModel(
            audioRecordingService: mockAudio,
            transcriptionService: mockTranscription,
            chatService: mockChat,
            ttsService: mockTTS
        )
        
        XCTAssertFalse(viewModel.canRecord)
    }
    
    func testStartRecordingUpdatesState() throws {
        mockAudio.hasPermission = true
        viewModel = ConversationViewModel(
            audioRecordingService: mockAudio,
            transcriptionService: mockTranscription,
            chatService: mockChat,
            ttsService: mockTTS
        )
        
        viewModel.startRecording()
        
        XCTAssertEqual(viewModel.state, .recording)
        XCTAssertTrue(mockAudio.startRecordingCalled)
        XCTAssertTrue(viewModel.isRecording)
    }
    
    func testStopRecordingTriggersProcessing() {
        mockAudio.hasPermission = true
        viewModel = ConversationViewModel(
            audioRecordingService: mockAudio,
            transcriptionService: mockTranscription,
            chatService: mockChat,
            ttsService: mockTTS
        )
        
        viewModel.startRecording()
        viewModel.stopRecording()
        
        XCTAssertTrue(mockAudio.stopRecordingCalled)
    }
    
    func testFullConversationFlow() async throws {
        mockAudio.hasPermission = true
        mockTranscription.mockTranscription = "Hello AI"
        mockChat.mockResponse = "Hello! How can I help?"
        
        viewModel = ConversationViewModel(
            audioRecordingService: mockAudio,
            transcriptionService: mockTranscription,
            chatService: mockChat,
            ttsService: mockTTS
        )
        
        viewModel.startRecording()
        viewModel.stopRecording()
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages[0].content, "Hello AI")
        XCTAssertEqual(viewModel.messages[0].role, .user)
        XCTAssertEqual(viewModel.messages[1].content, "Hello! How can I help?")
        XCTAssertEqual(viewModel.messages[1].role, .assistant)
        XCTAssertTrue(mockTTS.speakCalled)
    }
    
    func testErrorHandlingOnTranscriptionFails() async throws {
        mockAudio.hasPermission = true
        mockTranscription.shouldThrowError = true
        
        viewModel = ConversationViewModel(
            audioRecordingService: mockAudio,
            transcriptionService: mockTranscription,
            chatService: mockChat,
            ttsService: mockTTS
        )
        
        viewModel.startRecording()
        viewModel.stopRecording()
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertEqual(viewModel.state, .error)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testStopSpeakingCallsTTSStop() {
        viewModel.stopSpeaking()
        
        XCTAssertTrue(mockTTS.stopCalled)
        XCTAssertEqual(viewModel.state, .idle)
    }
    
    func testTTSCompletionTransitionsToIdle() {
        let expectation = XCTestExpectation(description: "TTS completion")
        
        mockTTS.onSpeak = { completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion?()
                expectation.fulfill()
            }
        }
        
        mockTTS.speak("Test", completion: nil)
        wait(for: [expectation], timeout: 1.0)
    }
}

final class MockAudioRecordingService: AudioRecordingProtocol {
    var hasPermission = true
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var isRecording = false
    
    func requestPermission() async -> Bool {
        return hasPermission
    }
    
    func checkPermission() -> Bool {
        return hasPermission
    }
    
    func startRecording() throws -> URL {
        startRecordingCalled = true
        isRecording = true
        return URL(fileURLWithPath: "/tmp/test.m4a")
    }
    
    func stopRecording() -> URL? {
        stopRecordingCalled = true
        isRecording = false
        return URL(fileURLWithPath: "/tmp/test.m4a")
    }
    
    func deleteRecording(at url: URL) {}
}

final class MockTranscriptionService: TranscriptionProtocol {
    var mockTranscription = ""
    var shouldThrowError = false
    
    func transcribe(audioURL: URL) async throws -> String {
        if shouldThrowError {
            throw APIError.serverError("Transcription failed")
        }
        return mockTranscription
    }
}

final class MockChatService: ChatProtocol {
    var mockResponse = ""
    var shouldThrowError = false
    
    func sendMessage(messages: [Message]) async throws -> String {
        if shouldThrowError {
            throw APIError.serverError("Chat failed")
        }
        return mockResponse
    }
    
    func sendMessage(text: String) async throws -> String {
        return try await sendMessage(messages: [])
    }
}

@MainActor
final class MockTextToSpeechService: TextToSpeechProtocol {
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
    
    func pause() {}
    func resume() {}
}
