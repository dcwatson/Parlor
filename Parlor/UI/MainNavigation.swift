//
//  MainNavigation.swift
//  Parlor
//
//  Created by Daniel Watson on 11/19/24.
//

import SwiftUI

enum NavSelection: Hashable {
    case console
    case channels
    case serverInfo
    case channel(IRCChannel)
    case conversation(IRCConversation)
}

struct ChannelNavItem: View {
    let channel: IRCChannel

    var body: some View {
        HStack {
            Text(channel.name)
            Spacer()
            Text(String(channel.users.count))
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
    }
}

struct MainNavigation: View {
    @Environment(IRCClient.self) var client

    @AppStorage("showServerInfo") private var showServerInfo = true

    @State private var selection: NavSelection? = .console

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("Console", systemImage: "apple.terminal")
                    .tag(NavSelection.console)

                if showServerInfo {
                    Label("Server Info", systemImage: "info.bubble")
                        .tag(NavSelection.serverInfo)
                }

                Label("Browse Channels", systemImage: "list.bullet")
                    .tag(NavSelection.channels)

                Section("Channels") {
                    ForEach(client.channels) { channel in
                        ChannelNavItem(channel: channel)
                            .tag(NavSelection.channel(channel))
                    }
                }

                Section("Conversations") {
                    ForEach(client.conversations) { conversation in
                        Text(conversation.user.nickname)
                            .tag(NavSelection.conversation(conversation))
                    }
                }
            }
            .listStyle(.sidebar)
        } detail: {
            switch selection {
            case nil:
                Text("Welcome to Parlor!")
            case .console:
                ConsoleView()
            case .serverInfo:
                ServerInfoView()
            case .channels:
                ChannelList()
            case .channel(let channel):
                ChannelView()
                    .environment(channel)
            case .conversation(let conversation):
                ConversationView()
                    .environment(conversation)
            }
        }
        .onReceive(client.events) { event in
            if case .app(let event) = event {
                switch event {
                case .jumpToChannel(let channel):
                    selection = .channel(channel)
                case .jumpToConversation(let conversation):
                    selection = .conversation(conversation)
                }
            }
        }
    }
}

#Preview(traits: .modifier(PreviewData())) {
    MainNavigation()
}
