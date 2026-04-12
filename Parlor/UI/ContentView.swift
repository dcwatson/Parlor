//
//  ContentView.swift
//  Parlor
//
//  Created by Daniel Watson on 11/15/24.
//

import SwiftUI

struct ContentView: View {
    @Environment(Parlor.self) private var parlor

    @State private var client: IRCClient?

    var body: some View {
        if let client {
            MainNavigation()
                .environment(client)
                .focusedSceneValue(client)
                .onDisappear {
                    client.disconnect()
                }
        } else {
            ServerManager { server in
                let client = IRCClient(server)
                client.connect()
                self.client = client
            }
        }
    }
}
