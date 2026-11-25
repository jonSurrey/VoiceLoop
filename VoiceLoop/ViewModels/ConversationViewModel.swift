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
        
        if !granted {
            fail(message: "VoiceLoop needs the microphone to hear you. Turn it on in Settings.", recovery: .openSettings)
        }
    }
    
    func startRecording() {
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
        guard case .retry(let step) = failure.recovery else {
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
            let recovery = recovery(for: error, retrying: .transcribe(recordingURL))
            if case .retry = recovery {
                keptRecording = recordingURL
            } else {
                recorder.deleteRecording(at: recordingURL)
            }
            fail(with: error, recovery: recovery)
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
            fail(with: error, recovery: recovery(for: error, retrying: .reply))
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
    
    private func recovery(for failure: Error, retrying step: ConversationError.RetryStep) -> ConversationError.Recovery? {
        switch failure {
        case TranscriptionError.notAuthorized:
            .openSettings
        case let failure as RetryableError where failure.isRetryable:
            .retry(step)
        default:
            nil
        }
    }
    
    private func fail(with failure: Error, recovery: ConversationError.Recovery? = nil) {
        fail(message: (failure as? LocalizedError)?.errorDescription ?? Self.genericErrorMessage, recovery: recovery)
    }
    
    private func fail(message: String, recovery: ConversationError.Recovery? = nil) {
        error = ConversationError(message: message, recovery: recovery)
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
