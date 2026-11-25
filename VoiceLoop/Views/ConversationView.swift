import SwiftUI

struct ConversationView: View {
    let viewModel: ConversationViewModel
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.messages.isEmpty {
                    emptyStateView
                } else {
                    messagesList
                }
                recordButtonSection
                    .padding(.bottom, Layout.recordButtonBottomPadding)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: Layout.titleSpacing) {
                        if viewModel.showsProgress {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(viewModel.title)
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.canStopSpeaking {
                        Button("Stop") {
                            viewModel.stopSpeaking()
                        }
                        .foregroundStyle(.red)
                    } else if viewModel.canClear {
                        Button(action: {
                            viewModel.clearConversation()
                        }) {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .alert("Oops!", isPresented: isShowingError, presenting: viewModel.error) { failure in
                Button("OK", role: .cancel) {}
                switch failure.recovery {
                case .retry:
                    Button("Try Again") {
                        Task { await viewModel.retry(failure) }
                    }
                case .openSettings:
                    Button("Open Settings", action: openSettings)
                case nil:
                    EmptyView()
                }
            } message: { failure in
                Text(failure.message)
            }
            .task {
                if !viewModel.hasMicrophonePermission {
                    await viewModel.requestMicrophonePermission()
                }
            }
        }
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            openURL(settingsURL)
        }
    }
    
    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.error != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissError()
                }
            }
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Layout.emptyStateSpacing) {
            Spacer()
            
            Image(systemName: "mic.fill")
                .font(.system(size: Layout.emptyStateIconSize))
                .foregroundStyle(.secondary)
            
            Text("Press and hold to speak")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Text("Your conversation will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
    
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Layout.messageSpacing) {
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
        VStack(spacing: Layout.recordSectionSpacing) {
            if let recordHint = viewModel.recordHint {
                Text(recordHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            RecordButton(
                isRecording: viewModel.isRecording,
                isEnabled: viewModel.canRecord,
                onStartRecording: {
                    viewModel.startRecording()
                },
                onStopRecording: {
                    Task { await viewModel.stopRecording() }
                }
            )
        }
        .padding(.top, Layout.recordSectionTopPadding)
    }

    private enum Layout {
        static let titleSpacing: CGFloat = 8
        static let emptyStateSpacing: CGFloat = 20
        static let emptyStateIconSize: CGFloat = 60
        static let messageSpacing: CGFloat = 8
        static let recordSectionSpacing: CGFloat = 12
        static let recordSectionTopPadding: CGFloat = 10
        static let recordButtonBottomPadding: CGFloat = 20
    }
}
