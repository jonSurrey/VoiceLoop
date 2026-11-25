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
                    .phaseAnimator([false, true]) { ring, isExpanded in
                        ring
                            .scaleEffect(isExpanded ? Layout.ringExpandedScale : 1)
                            .opacity(isExpanded ? Layout.ringExpandedOpacity : 1)
                    } animation: { _ in
                        .easeInOut(duration: Layout.ringPulseDuration)
                    }
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
            pressing: { isPressing in
                if isPressing {
                    onStartRecording()
                } else {
                    onStopRecording()
                }
            }, perform: {}
        )
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : Layout.disabledOpacity)
    }

    private enum Layout {
        static let ringDiameter: CGFloat = 90
        static let ringLineWidth: CGFloat = 4
        static let ringExpandedScale: CGFloat = 1.2
        static let ringExpandedOpacity: CGFloat = 0.5
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
