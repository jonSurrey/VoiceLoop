import SwiftUI

struct MessageRow: View {
    let message: Message
    
    private var bubbleColor: Color {
        message.role == .user ? .blue : Color(.gray)
    }
    
    private var textColor: Color {
        message.role == .user ? .white : .primary
    }
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(bubbleColor)
                    .foregroundColor(textColor)
                    .cornerRadius(16)
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .assistant {
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

