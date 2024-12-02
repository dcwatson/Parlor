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

struct ServerCap: Identifiable {
    var name: String
    var fullName: String
    var enabled: Bool

    var id: String { name }
    var enabledSort: String { enabled ? "0" : "1" }
    var compactFullName: String {
        enabled ? "✓ " + fullName : fullName
    }
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

struct ServerCapabilityTable: View {
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        private var isCompact: Bool { horizontalSizeClass == .compact }
    #else
        private let isCompact = false
    #endif

    @Binding var serverCaps: [ServerCap]
    @State private var sortOrder = [KeyPathComparator(\ServerCap.name)]

    var body: some View {
        Table(serverCaps, sortOrder: $sortOrder) {
            TableColumn("Capability", value: \.name) { cap in
                Text(isCompact ? cap.compactFullName : cap.fullName)
            }
            TableColumn("Enabled", value: \.enabledSort) { cap in
                Text(cap.enabled ? "Yes" : "")
                    .bold(cap.enabled)
            }
        }
        .onChange(of: sortOrder) {
            serverCaps.sort(using: sortOrder)
        }
    }
}

struct ServerInfoView: View {
    @Environment(IRCClient.self) var client

    @State private var serverSupport: [ServerSupport] = []
    @State private var serverCaps: [ServerCap] = []
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
                    ServerCapabilityTable(serverCaps: $serverCaps)
                }
            }
        }
        .navigationTitle("Server Info")
        .task {
            serverSupport = []
            for (key, value) in client.supports.sorted(by: { $0.key < $1.key }) {
                serverSupport.append(ServerSupport(key: key, value: value))
            }

            serverCaps = []
            for cap in client.availableCapabilities.sorted(by: { $0.name < $1.name }) {
                serverCaps.append(
                    ServerCap(
                        name: cap.name, fullName: cap.stringValue,
                        enabled: client.capabilities.has(cap.name, vendor: cap.vendor))
                )
            }
        }
    }
}
