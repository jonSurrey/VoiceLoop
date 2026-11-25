import SwiftUI

struct MessageRow: View {
    let message: Message
    
    private var bubbleColor: Color {
        message.role == .user ? .accentColor : Color(.secondarySystemBackground)
    }
    
    private var textColor: Color {
        message.role == .user ? .white : .primary
    }
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: Layout.timestampSpacing) {
                Text(message.content)
                    .padding(Layout.bubblePadding)
                    .background(bubbleColor)
                    .foregroundColor(textColor)
                    .cornerRadius(Layout.bubbleCornerRadius)
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: Layout.maxBubbleWidth, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .assistant {
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, Layout.rowVerticalPadding)
    }

    private enum Layout {
        static let timestampSpacing: CGFloat = 4
        static let bubblePadding: CGFloat = 12
        static let bubbleCornerRadius: CGFloat = 16
        static let maxBubbleWidth: CGFloat = 280
        static let rowVerticalPadding: CGFloat = 4
    }
}
