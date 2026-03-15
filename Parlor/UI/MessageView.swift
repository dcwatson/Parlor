//
//  MessageView.swift
//  Parlor
//
//  Created by Daniel Watson on 11/29/24.
//

import SwiftUI

struct MessageView: View {
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        private var isCompact: Bool { horizontalSizeClass == .compact }
    #else
        private let isCompact = false
    #endif

    @AppStorage("showTimestamps") private var showTimestamps = true
    @AppStorage("monospace") private var monospace = false

    let message: IRCMessage

    var body: some View {
        if isCompact {
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline) {
                    Text(message.nickname)
                        .bold()
                        .foregroundStyle(Color.accentColor)
                    if showTimestamps && message.timeChanged {
                        Text(timeFormatter.string(from: message.timestamp))
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                }
                
                Text(message.message)
            }
            .monospaced(monospace)
            .textSelection(.enabled)
        }
        else {
            if message.dateChanged {
                HStack {
                    Spacer()
                    Text(dateFormatter.string(from: message.timestamp))
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                    Spacer()
                }
                .monospaced(monospace)
                .textSelection(.enabled)
            }
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                if showTimestamps {
                    Text(message.maybeTimeString)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .frame(width: 60, alignment: .trailing)
                }
                Text(message.nickname)
                    .bold()
                    .foregroundStyle(Color.accentColor)
                Text(message.message)
            }
            .monospaced(monospace)
            .textSelection(.enabled)
        }
    }
}

#Preview(traits: .modifier(PreviewData())) {
    @Previewable @Environment(IRCClient.self) var client

    VStack(alignment: .leading) {
        MessageView(message: client.channels[0].messages[0])
        MessageView(message: client.channels[0].messages[1])
    }
        .padding()
}
