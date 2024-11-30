//
//  ChannelView.swift
//  Parlor
//
//  Created by Daniel Watson on 11/19/24.
//

import SwiftUI

struct ChannelView: View {
    @Environment(IRCClient.self) var client
    @Environment(IRCChannel.self) var channel

    @State private var inputText: String = ""
    @FocusState private var inputFocused: Bool

    #if os(macOS)
        @State private var showingUsers: Bool = true
    #else
        @State private var showingUsers: Bool = false
    #endif

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 5) {
                    ForEach(channel.messages) { message in
                        MessageView(message: message)
                    }
                }
                .padding()
            }
            .background(.background)
            .defaultScrollAnchor(.bottom)

            TextField("Message \(channel.name)", text: $inputText)
                .padding(10)
                .textFieldStyle(.plain)
                .focused($inputFocused)
                .onSubmit {
                    client.send(.privmsg(target: channel.name, message: inputText))
                    inputText = ""
                }
        }
        .navigationTitle(channel.name)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            inputFocused = true
        }
        .inspector(isPresented: $showingUsers) {
            UserList()
                #if os(macOS)
                    .inspectorColumnWidth(min: 200, ideal: 200, max: 400)
                #endif
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    client.send(.part(channel: channel.name))
                } label: {
                    Label("Leave", systemImage: "slash.circle")
                }

                Button {
                    showingUsers.toggle()
                } label: {
                    Label("Toggle Users", systemImage: "person")
                }
            }
        }
    }
}

#Preview(traits: .modifier(PreviewData())) {
    ChannelView()
}
