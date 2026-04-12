//
//  ServerManager.swift
//  Parlor
//
//  Created by Daniel Watson on 4/1/26.
//

import SwiftData
import SwiftUI

struct ServerManager: View {
    @Environment(\.modelContext) var modelContext

    let onConnect: (Server) -> Void

    @Query private var servers: [Server]
    @State private var selectedServer: Server?

    @State private var showingConfirmDelete = false
    @State private var deletingServer: Server?

    var body: some View {
        NavigationSplitView {
            List(servers, selection: $selectedServer) { server in
                Text(server.name)
                    .tag(server)
            }
            .navigationSplitViewColumnWidth(200)
            //.frame(minWidth: 100, idealWidth: 200, maxWidth: 300)
            //.toolbar(removing: .sidebarToggle)
            .contextMenu(forSelectionType: Server.self) { selection in
                if selection.count == 1 {
                    Button("Delete server…", role: .destructive) {
                        deletingServer = selection.first
                        showingConfirmDelete = true
                    }
                }
            } primaryAction: { selection in
                if let server = selection.first {
                    onConnect(server)
                }
            }
            .toolbar {
                ToolbarSpacer(.flexible)
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        let newServer = Server()
                        modelContext.insert(newServer)
                        selectedServer = newServer
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .onDeleteCommand {
                deletingServer = selectedServer
                showingConfirmDelete = true
            }
        } detail: {
            if let server = selectedServer {
                ServerTabs(server: server)
                    .scenePadding()
                    .safeAreaInset(edge: .bottom) {
                        VStack {
                            Divider()
                            Button("Connect") {
                                onConnect(server)
                            }
                        }
                        .padding()
                    }
            } else {
                Text("Select a server or add a new one!")
            }
        }
        .confirmationDialog(
            "Are you sure?",
            isPresented: $showingConfirmDelete,
            presenting: deletingServer
        ) { server in
            Button("Delete Server", role: .destructive) {
                modelContext.delete(server)
                selectedServer = nil
            }
        } message: { server in
            Text("This action cannot be undone.")
        }
    }
}

#Preview(traits: .modifier(PreviewData())) {
    ServerManager() { server in }
}
