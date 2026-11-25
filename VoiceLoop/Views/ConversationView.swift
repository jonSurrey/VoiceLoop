import SwiftUI

struct ConversationView: View {
    @ObservedObject var viewModel: ConversationViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.messages.isEmpty {
                    emptyStateView
                } else {
                    messagesList
                }
                recordButtonSection
                    .padding(.bottom, 20)
            }
            .background(Color(.white))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        if viewModel.state != .idle && viewModel.state != .error {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(viewModel.state == .idle ? "Voice Assistant" : viewModel.statusText)
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.state == .speaking {
                        Button("Stop") {
                            viewModel.stopSpeaking()
                        }
                        .foregroundColor(.red)
                    } else if !viewModel.messages.isEmpty {
                        Button(action: {
                            viewModel.clearConversation()
                        }) {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .alert("Oops!", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.dismissError()
                }
                if viewModel.hasRecordingData {
                    Button("Try Again") {
                        viewModel.retry()
                    }
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.body)
                }
            }
            .task {
                if !viewModel.hasMicrophonePermission {
                    await viewModel.requestMicrophonePermission()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "mic.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Press and hold to speak")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("Your conversation will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.messages) { message in
                        MessageRow(message: message)
                            .id(message.id)
                    }
                }
                .padding(.vertical)
            }
            .onChange(of: viewModel.messages.count) {
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var recordButtonSection: some View {
        VStack(spacing: 12) {
            if viewModel.state == .idle {
                Text(viewModel.messages.isEmpty ? "Hold to record" : "Hold to continue")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            RecordButton(
                isRecording: viewModel.isRecording,
                isEnabled: viewModel.canRecord,
                onStartRecording: {
                    viewModel.startRecording()
                },
                onStopRecording: {
                    viewModel.stopRecording()
                }
            )
        }
        .padding(.top, 10)
    }
}
