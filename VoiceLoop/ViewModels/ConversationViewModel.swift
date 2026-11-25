import Foundation
import Observation

@Observable
final class ConversationViewModel {
    var messages: [Message] = []
    var state: ConversationState = .idle
    var errorMessage: String?
    var hasMicrophonePermission: Bool = false
    
    private static let genericErrorMessage = "Something went wrong. Please try again."
    
    private let recorder: AudioRecording
    private let transcriber: Transcribing
    private let chat: ChatCompleting
    private let synthesizer: SpeechSynthesizing
    
    private var retryStep: RetryStep?
    
    private enum RetryStep {
        case transcribe(URL)
        case reply
    }
    
    var statusText: String {
        switch state {
        case .idle:
            return ""
        case .recording:
            return "Recording..."
        case .transcribing:
            return "Transcribing audio..."
        case .generating:
            return "Generating response..."
        case .speaking:
            return "Speaking response..."
        case .error:
            return "Error occurred"
        }
    }
    
    var canRetry: Bool {
        retryStep != nil
    }
    
    var isRecording: Bool {
        state == .recording
    }
    
    var canRecord: Bool {
        hasMicrophonePermission && 
        (state.canStartRecording || state == .recording)
    }
    
    init(
        recorder: AudioRecording,
        transcriber: Transcribing,
        chat: ChatCompleting,
        synthesizer: SpeechSynthesizing
    ) {
        self.recorder = recorder
        self.transcriber = transcriber
        self.chat = chat
        self.synthesizer = synthesizer
        
        self.hasMicrophonePermission = recorder.checkPermission()
        recorder.onInterruption = { [weak self] in
            self?.handleInterruption()
        }
    }
    
    func requestMicrophonePermission() async {
        let granted = await recorder.requestPermission()
        hasMicrophonePermission = granted
        
        guard granted else {
            errorMessage = "Microphone permission is required to use this app."
            state = .error
            return
        }
    }
    
    func startRecording() {
        guard hasMicrophonePermission else {
            errorMessage = "Microphone access is required. Please enable it in Settings."
            state = .error
            return
        }
        
        guard state.canStartRecording else {
            return
        }
        
        synthesizer.stop()
        do {
            try recorder.startRecording()
            state = .recording
            errorMessage = nil
        } catch {
            fail(with: error)
        }
    }
    
    func stopRecording() async {
        guard state.canStopRecording else {
            return
        }
        
        guard let recordingURL = recorder.stopRecording() else {
            errorMessage = Self.genericErrorMessage
            state = .error
            return
        }
        
        await transcribe(recordingURL)
    }
    
    func retry() async {
        guard let step = retryStep else {
            return
        }
        retryStep = nil
        errorMessage = nil
        
        switch step {
        case .transcribe(let url):
            await transcribe(url)
        case .reply:
            await reply()
        }
    }
    
    func dismissError() {
        if case .transcribe(let url) = retryStep {
            recorder.deleteRecording(at: url)
        }
        retryStep = nil
        errorMessage = nil
        state = .idle
    }
    
    private func transcribe(_ recordingURL: URL) async {
        state = .transcribing
        let transcript: String
        do {
            transcript = try await transcriber.transcribe(recordingURL)
        } catch {
            fail(with: error, retry: .transcribe(recordingURL))
            return
        }
        
        recorder.deleteRecording(at: recordingURL)
        messages.append(Message(role: .user, content: transcript))
        await reply()
    }
    
    private func reply() async {
        state = .generating
        let answer: String
        do {
            answer = try await chat.reply(to: messages)
        } catch {
            fail(with: error, retry: .reply)
            return
        }
        
        messages.append(Message(role: .assistant, content: answer))
        state = .speaking
        await synthesizer.speak(answer)
        // The user may have stopped speech or started a new recording meanwhile.
        if state == .speaking {
            state = .idle
        }
    }
    
    private func fail(with error: Error, retry step: RetryStep? = nil) {
        errorMessage = (error as? LocalizedError)?.errorDescription ?? Self.genericErrorMessage
        retryStep = step
        state = .error
    }
    
    private func handleInterruption() {
        guard state == .recording else {
            return
        }
        if let url = recorder.stopRecording() {
            recorder.deleteRecording(at: url)
        }
        errorMessage = "Recording was interrupted."
        state = .error
    }
    
    func stopSpeaking() {
        synthesizer.stop()
        state = .idle
    }
    
    func clearConversation() {
        messages.removeAll()
        state = .idle
        errorMessage = nil
        synthesizer.stop()
    }
}
