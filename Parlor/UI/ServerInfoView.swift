//
//  ServerInfoView.swift
//  Parlor
//
//  Created by Daniel Watson on 11/29/24.
//

import SwiftUI

struct ServerSupport: Identifiable {
    var key: String
    var value: String

    var id: String { key }
}

enum InfoTable {
    case supports
    case capabilities
}

struct ServerSupportTable: View {
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        private var isCompact: Bool { horizontalSizeClass == .compact }
    #else
        private let isCompact = false
    #endif

    @Binding var serverSupport: [ServerSupport]
    @State private var sortOrder = [KeyPathComparator(\ServerSupport.key)]

    var body: some View {
        Table(serverSupport, sortOrder: $sortOrder) {
            TableColumn("Key", value: \.key) { support in
                if isCompact {
                    VStack(alignment: .leading) {
                        Text(support.key)
                        if !support.value.isEmpty {
                            Text(support.value)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text(support.key)
                }
            }
            TableColumn("Value", value: \.value)
        }
        .onChange(of: sortOrder) {
            serverSupport.sort(using: sortOrder)
        }
    }
}

struct ServerInfoView: View {
    @Environment(IRCClient.self) var client

    @State private var serverSupport: [ServerSupport] = []
    @State private var showTable: InfoTable = .supports

    var body: some View {
        VStack {
            Picker("", selection: $showTable) {
                Text("Supports").tag(InfoTable.supports)
                Text("Capabilities").tag(InfoTable.capabilities)
            }
            .pickerStyle(.segmented)
            .padding()

            Group {
                switch showTable {
                case .supports:
                    ServerSupportTable(serverSupport: $serverSupport)
                case .capabilities:
                    Table(client.capabilities) {
                        TableColumn("Capability", value: \.id)
                    }
                }
            }
        }
        .navigationTitle("Server Info")
        .task {
            serverSupport = []
            for (key, value) in client.supports {
                serverSupport.append(ServerSupport(key: key, value: value))
            }
            serverSupport.sort(by: { $0.key < $1.key })
        }
    }
}
