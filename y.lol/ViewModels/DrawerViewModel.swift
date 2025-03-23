import SwiftUI

struct DrawerView: View {
    let conversations: [ChatSession]

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(conversations, id: \.id) { conversation in
                Text(conversation.messages.first?.content ?? "No messages")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 50) // Adjust for navigation bar
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .shadow(radius: 5)
    }
}
