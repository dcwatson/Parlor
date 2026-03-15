//
//  ChannelView.swift
//  Parlor
//
//  Created by Daniel Watson on 11/19/24.
//

import SwiftUI

struct ChannelView: View {
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        private var isCompact: Bool { horizontalSizeClass == .compact }
    #else
        private let isCompact = false
    #endif

    @Environment(IRCClient.self) var client
    @Environment(IRCChannel.self) var channel

    @AppStorage("monospace") private var monospace = false

    @State private var inputText: String = ""
    @State private var showingTopicAlert: Bool = false
    @State private var newTopic: String = ""

    @FocusState private var inputFocused: Bool

    #if os(macOS)
        @State private var showingUsers: Bool = true
    #else
        @State private var showingUsers: Bool = false
    #endif

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: isCompact ? 15 : 5) {
                ForEach(channel.messages) { message in
                    MessageView(message: message)
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: 80)
        }
        .background(.background)
        .defaultScrollAnchor(.bottom)
        .overlay(alignment: .bottom) {
            InputView(placeholder: "Message \(channel.name)", text: $inputText) { text in
                client.send(.privmsg(target: channel.name, message: text))
                inputText = ""
            }
        }
        .navigationTitle(channel.name)
        .navigationSubtitle(channel.topic)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            inputFocused = true
        }
        .inspector(isPresented: $showingUsers) {
            UserList()
                #if os(macOS)
                    .inspectorColumnWidth(min: 200, ideal: 250, max: 400)
                #endif
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showingTopicAlert = true
                } label: {
                    Label("Set Topic", systemImage: "text.bubble")
                }
                .alert("Set Topic", isPresented: $showingTopicAlert) {
                    TextField("New topic for \(channel.name)", text: $newTopic)
                    Button("OK") {
                        client.send(.topic(channel: channel.name, topic: newTopic))
                        newTopic = ""
                    }
                }

                Button {
                    client.send(.part(channel: channel.name))
                    client.appEvent(.popNavigation)
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
