import Foundation
import SwiftUI

@MainActor
class ConversationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var messages: [Message] = []
    @Published var state: AppState = .idle
    @Published var errorMessage: String?
    @Published var hasMicrophonePermission: Bool = false
    @Published var hasRecordingData: Bool = false
    
    // MARK: - Services
    
    private let audioRecordingService: AudioRecordingProtocol
    private let transcriptionService: TranscriptionProtocol
    private let chatService: ChatProtocol
    private let ttsService: TextToSpeechProtocol
    
    // MARK: - Private Properties
    
    private var currentRecordingURL: URL?
    
    // MARK: - Status Text
    
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
    
    // MARK: - Recording State
    
    var isRecording: Bool {
        state == .recording
    }
    
    var canRecord: Bool {
        hasMicrophonePermission && 
        (state.canStartRecording || state == .recording)
    }
    
    // MARK: - Initialization
    
    init() {
        self.audioRecordingService = AudioRecordingService()
        self.transcriptionService = TranscriptionService()
        self.chatService = ChatService()
        self.ttsService = TextToSpeechService()
        
        self.hasMicrophonePermission = audioRecordingService.checkPermission()
    }
    
    init(
        audioRecordingService: AudioRecordingProtocol,
        transcriptionService: TranscriptionProtocol,
        chatService: ChatProtocol,
        ttsService: TextToSpeechProtocol
    ) {
        self.audioRecordingService = audioRecordingService
        self.transcriptionService = transcriptionService
        self.chatService = chatService
        self.ttsService = ttsService
        
        self.hasMicrophonePermission = audioRecordingService.checkPermission()
    }
    
    // MARK: - Permissions
    
    func requestMicrophonePermission() async {
        let granted = await audioRecordingService.requestPermission()
        hasMicrophonePermission = granted
        
        guard granted else {
            errorMessage = "Microphone permission is required to use this app."
            state = .error
            return
        }
    }
    
    // MARK: - Recording Control
    
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
            currentRecordingURL = try audioRecordingService.startRecording()
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
        
        guard let recordingURL = audioRecordingService.stopRecording() else {
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
    
    // MARK: - Processing Pipeline
    
    /// Process the recorded audio through the full pipeline
    /// 1. Transcribe audio to text
    /// 2. Send text to chat API
    /// 3. Display response
    /// 4. Optionally speak response
    private func processRecording(at url: URL) async {
        do {
            // Step 1: Transcribe audio to text
            state = .transcribing
            let transcribedText = try await transcriptionService.transcribe(audioURL: url)
            
            // Add user message to conversation
            let userMessage = Message(role: .user, content: transcribedText)
            messages.append(userMessage)
            
            // Step 2: Send to chat API
            state = .generating
            let aiResponse = try await chatService.sendMessage(messages: messages)
            
            // Add assistant message to conversation
            let assistantMessage = Message(role: .assistant, content: aiResponse)
            messages.append(assistantMessage)
            
            // Step 3: Speak the response
            state = .speaking
            ttsService.speak(aiResponse) { [weak self] in
                Task { @MainActor in
                    self?.state = .idle
                }
            }
            
            // Clean up the recording file
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
        audioRecordingService.deleteRecording(at: url)
        hasRecordingData = false
    }
    
    // MARK: - Error Handling
    
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
    
    // MARK: - TTS Control
    
    func stopSpeaking() {
        ttsService.stop()
        state = .idle
    }
    
    // MARK: - Conversation Management
    
    func clearConversation() {
        messages.removeAll()
        state = .idle
        errorMessage = nil
        ttsService.stop()
    }
}


