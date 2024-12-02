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
    @AppStorage("monospace") private var monospace = false

    let message: IRCMessage

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            if showTimestamps {
                Text(timeFormatter.string(from: message.timestamp))
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .frame(width: 60)
            }
            Text(message.user.nickname)
                .bold()
                .foregroundStyle(Color.accentColor)
            Text(message.message)
        }
        .monospaced(monospace)
        .textSelection(.enabled)
    }
}

#Preview(traits: .modifier(PreviewData())) {
    @Previewable @Environment(IRCClient.self) var client

    MessageView(message: client.channels[0].messages[0])
        .padding()
}
