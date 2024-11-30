//
//  ConsoleView.swift
//  Parlor
//
//  Created by Daniel Watson on 11/24/24.
//

import SwiftUI

struct ConsoleLine: View {
    let line: IRCLine

    var lineColor: Color {
        if line.outgoing {
            return .blue
        }
        if line.error != nil {
            return .red
        }
        return line.reply == nil ? .green : .primary
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: line.outgoing ? "arrow.right" : "arrow.left")
            Text(line.stringValue)
                .textSelection(.enabled)
        }
        .foregroundStyle(lineColor)
    }
}

struct ConsoleView: View {
    @Environment(IRCClient.self) var client

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 5) {
                ForEach(client.log) { line in
                    ConsoleLine(line: line)
                }
            }
            .padding()
        }
        .defaultScrollAnchor(.bottom)
        .background(.background)
        .navigationTitle("Console")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview(traits: .modifier(PreviewData())) {
    ConsoleView()
}
