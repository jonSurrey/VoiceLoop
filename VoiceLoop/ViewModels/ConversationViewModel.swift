import Foundation
import Observation

@Observable
final class ConversationViewModel {
    var messages: [Message] = []
    var state: ConversationState = .idle
    var errorMessage: String?
    var hasMicrophonePermission: Bool = false
    var hasRecordingData: Bool = false
    
    private let recorder: AudioRecording
    private let transcriber: Transcribing
    private let chat: ChatCompleting
    private let synthesizer: SpeechSynthesizing
    
    private var currentRecordingURL: URL?
    
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
        
        do {
            currentRecordingURL = try recorder.startRecording()
            state = .recording
            errorMessage = nil
        } catch let error as RecordingError {
            errorMessage = error.errorDescription
            state = .error
        } catch {
            errorMessage = "Couldn't start recording. Please try again."
            state = .error
        }
    }
    
    func stopRecording() {
        guard state.canStopRecording else {
            return
        }
        
        guard let recordingURL = recorder.stopRecording() else {
            errorMessage = "Something went wrong. Please try again."
            state = .error
            return
        }
        
        currentRecordingURL = recordingURL
        hasRecordingData = true
        
        Task {
            await processRecording(at: recordingURL)
        }
    }
    
    private func processRecording(at url: URL) async {
        do {
            state = .transcribing
            let transcribedText = try await transcriber.transcribe(url)
            
            let userMessage = Message(role: .user, content: transcribedText)
            messages.append(userMessage)
            
            state = .generating
            let aiResponse = try await chat.reply(to: messages)
            
            let assistantMessage = Message(role: .assistant, content: aiResponse)
            messages.append(assistantMessage)
            
            state = .speaking
            synthesizer.speak(aiResponse) { [weak self] in
                Task { @MainActor in
                    self?.state = .idle
                }
            }
            
            deleteRecording(url)
                        
        } catch let error as APIError {
            errorMessage = error.errorDescription
            state = .error
            cleanupRecording()
        } catch let error as RecordingError {
            errorMessage = error.errorDescription
            state = .error
            cleanupRecording()
        } catch {
            errorMessage = "Something went wrong. Please try again."
            state = .error
            cleanupRecording()
        }
    }
    
    private func cleanupRecording() {
        guard let url = currentRecordingURL else { return }
        deleteRecording(url)
    }
    
    func deleteRecording(_ url: URL) {
        recorder.deleteRecording(at: url)
        hasRecordingData = false
    }
    
    func retry() {
        errorMessage = nil
        
        guard let url = currentRecordingURL else {
            state = .idle
            return
        }
        
        Task {
            await processRecording(at: url)
        }
    }
    
    func dismissError() {
        errorMessage = nil
        state = .idle
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
