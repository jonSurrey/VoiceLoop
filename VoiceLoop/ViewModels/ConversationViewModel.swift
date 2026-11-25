import Foundation
import Observation

@Observable
final class ConversationViewModel {
    var messages: [Message] = []
    var state: ConversationState = .idle
    var error: ConversationError?
    var hasMicrophonePermission: Bool = false
    
    private static let genericErrorMessage = "Something went wrong. Please try again."
    
    private let recorder: AudioRecording
    private let transcriber: Transcribing
    private let chat: ChatCompleting
    private let synthesizer: SpeechSynthesizing
    
    private var keptRecording: URL?
    
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
            fail(message: "Microphone permission is required to use this app.")
            return
        }
    }
    
    func startRecording() {
        guard hasMicrophonePermission else {
            fail(message: "Microphone access is required. Please enable it in Settings.")
            return
        }
        
        guard state.canStartRecording else {
            return
        }
        
        synthesizer.stop()
        discardKeptRecording()
        do {
            try recorder.startRecording()
            state = .recording
        } catch {
            fail(with: error)
        }
    }
    
    func stopRecording() async {
        guard state.canStopRecording else {
            return
        }
        
        guard let recordingURL = recorder.stopRecording() else {
            fail(message: Self.genericErrorMessage)
            return
        }
        
        await transcribe(recordingURL)
    }
    
    func retry(_ failure: ConversationError) async {
        guard let step = failure.retryStep else {
            return
        }
        error = nil
        
        switch step {
        case .transcribe(let url):
            await transcribe(url)
        case .reply:
            await reply()
        }
    }
    
    func dismissError() {
        error = nil
        if state == .error {
            state = .idle
        }
    }
    
    private func transcribe(_ recordingURL: URL) async {
        state = .transcribing
        let transcript: String
        do {
            transcript = try await transcriber.transcribe(recordingURL)
        } catch {
            keptRecording = recordingURL
            fail(with: error, retry: .transcribe(recordingURL))
            return
        }
        
        recorder.deleteRecording(at: recordingURL)
        keptRecording = nil
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
    
    private func fail(with failure: Error, retry step: ConversationError.RetryStep? = nil) {
        fail(message: (failure as? LocalizedError)?.errorDescription ?? Self.genericErrorMessage, retry: step)
    }
    
    private func fail(message: String, retry step: ConversationError.RetryStep? = nil) {
        error = ConversationError(message: message, retryStep: step)
        state = .error
    }
    
    private func discardKeptRecording() {
        if let keptRecording {
            recorder.deleteRecording(at: keptRecording)
        }
        keptRecording = nil
    }
    
    private func handleInterruption() {
        guard state == .recording else {
            return
        }
        if let url = recorder.stopRecording() {
            recorder.deleteRecording(at: url)
        }
        fail(message: "Recording was interrupted.")
    }
    
    func stopSpeaking() {
        synthesizer.stop()
        state = .idle
    }
    
    func clearConversation() {
        messages.removeAll()
        state = .idle
        error = nil
        synthesizer.stop()
    }
}
