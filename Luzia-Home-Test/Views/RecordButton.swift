import SwiftUI

struct RecordButton: View {
    let isRecording: Bool
    let isEnabled: Bool
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    
    private var buttonColor: Color {
        if !isEnabled {
            return .gray
        }
        return isRecording ? .red : .blue
    }
    
    var body: some View {
        ZStack {
            if isRecording {
                Circle()
                    .stroke(.red, lineWidth: 4)
                    .frame(width: 90, height: 90)
                    .scaleEffect(isRecording ? 1.2 : 1.0)
                    .opacity(isRecording ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isRecording)
            }
            Circle()
                .fill(buttonColor)
                .frame(width: 70, height: 70)
                .shadow(color: .black.opacity(0.2), radius: 5, y: 3)
                .overlay(
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                )
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isRecording)
        }
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                if pressing {
                    if !isRecording && isEnabled {
                        onStartRecording()
                    }
                } else {
                    if isRecording {
                        onStopRecording()
                    }
                }
            }, perform: {}
        )
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}

