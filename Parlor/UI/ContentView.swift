//
//  ContentView.swift
//  Parlor
//
//  Created by Daniel Watson on 11/15/24.
//

import SwiftUI

struct ContentView: View {
    @State private var client = IRCClient()

    var body: some View {
        if client.connected {
            MainNavigation()
                .environment(client)
        } else {
            ConnectForm()
                .environment(client)
                #if os(macOS)
                    .frame(maxWidth: 400)
                #endif
        }
    }
}
