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

struct ServerInfoView: View {
    @Environment(IRCClient.self) var client

    @State private var serverSupport: [ServerSupport] = []

    var body: some View {
        Table(serverSupport) {
            TableColumn("Key", value: \.key)
            TableColumn("Value", value: \.value)
        }
        Table(client.capabilities) {
            TableColumn("Capability", value: \.id)
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
