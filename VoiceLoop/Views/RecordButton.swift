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
                    .stroke(.red, lineWidth: Layout.ringLineWidth)
                    .frame(width: Layout.ringDiameter, height: Layout.ringDiameter)
                    .scaleEffect(isRecording ? Layout.ringRecordingScale : 1)
                    .opacity(isRecording ? Layout.ringRecordingOpacity : 1)
                    .animation(.easeInOut(duration: Layout.ringPulseDuration).repeatForever(autoreverses: true), value: isRecording)
            }
            Circle()
                .fill(buttonColor)
                .frame(width: Layout.buttonDiameter, height: Layout.buttonDiameter)
                .shadow(color: .black.opacity(Layout.shadowOpacity), radius: Layout.shadowRadius, y: Layout.shadowOffset)
                .overlay(
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: Layout.iconSize))
                        .foregroundColor(.white)
                )
                .scaleEffect(isRecording ? Layout.buttonRecordingScale : 1)
                .animation(.spring(response: Layout.buttonSpringResponse), value: isRecording)
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
        .opacity(isEnabled ? 1 : Layout.disabledOpacity)
    }

    private enum Layout {
        static let ringDiameter: CGFloat = 90
        static let ringLineWidth: CGFloat = 4
        static let ringRecordingScale: CGFloat = 1.2
        static let ringRecordingOpacity: CGFloat = 0.5
        static let ringPulseDuration: TimeInterval = 0.8
        static let buttonDiameter: CGFloat = 70
        static let buttonRecordingScale: CGFloat = 1.1
        static let buttonSpringResponse: TimeInterval = 0.3
        static let iconSize: CGFloat = 28
        static let shadowOpacity: CGFloat = 0.2
        static let shadowRadius: CGFloat = 5
        static let shadowOffset: CGFloat = 3
        static let disabledOpacity: CGFloat = 0.5
    }
}
