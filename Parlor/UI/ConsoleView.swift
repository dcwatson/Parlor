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
            Text(line.toString())
                .textSelection(.enabled)
        }
        .foregroundStyle(lineColor)
    }
}

struct ConsoleBatch: View {
    let batch: IRCBatch

    var body: some View {
        DisclosureGroup("BATCH \(batch.id) (\(batch.type))") {
            LazyVStack(alignment: .leading, spacing: 5) {
                ForEach(batch.lines) { line in
                    ConsoleLine(line: line)
                }
            }
        }
    }
}

struct ConsoleView: View {
    @Environment(IRCClient.self) var client

    @AppStorage("monospace") private var monospace = false

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 5) {
                ForEach(client.log) { entry in
                    switch entry {
                    case .line(let line):
                        ConsoleLine(line: line)
                    case .batch(let batch):
                        ConsoleBatch(batch: batch)
                    }
                }
            }
            .padding()
            .monospaced(monospace)
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
