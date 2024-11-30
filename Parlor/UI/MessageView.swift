//
//  MessageView.swift
//  Parlor
//
//  Created by Daniel Watson on 11/29/24.
//

import SwiftUI

let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

struct MessageView: View {
    @AppStorage("showTimestamps") private var showTimestamps = true

    let message: IRCMessage

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            if showTimestamps {
                Text(timeFormatter.string(from: message.timestamp))
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .frame(width: 50)
            }
            Text(message.user.nickname)
                .bold()
                .foregroundStyle(Color.accentColor)
            Text(LocalizedStringKey(message.message))
        }
    }
}

#Preview(traits: .modifier(PreviewData())) {
    @Previewable @Environment(IRCClient.self) var client

    MessageView(message: client.channels[0].messages[0])
        .padding()
}
