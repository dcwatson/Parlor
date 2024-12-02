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

    @State private var selection: NavSelection? = nil
    @State private var showingAppSettings: Bool = false
    @State private var showingJoinAlert: Bool = false
    @State private var channelOrNick: String = ""

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

                if !client.channels.isEmpty {
                    Section("Channels") {
                        ForEach(client.channels) { channel in
                            ChannelNavItem(channel: channel)
                                .tag(NavSelection.channel(channel))
                        }
                    }
                }

                if !client.conversations.isEmpty {
                    Section("Conversations") {
                        ForEach(client.conversations) { conversation in
                            Text(conversation.user.nickname)
                                .tag(NavSelection.conversation(conversation))
                        }
                    }
                }

                #if os(iOS)
                    Button {
                        showingAppSettings = true
                    } label: {
                        Label("App Settings", systemImage: "gear")
                    }
                #endif
            }
            .listStyle(.sidebar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingJoinAlert = true
                    } label: {
                        Label("Join", systemImage: "plus")
                    }
                    .alert("Join/Message", isPresented: $showingJoinAlert) {
                        TextField("#channel or nickname", text: $channelOrNick)
                        Button("OK") {
                            if channelOrNick.hasPrefix("#") {
                                client.send(.join(channel: channelOrNick))
                            } else {
                                if let user = client.getUser(channelOrNick, create: true),
                                    let convo = client.getConversation(user, create: true)
                                {
                                    client.appEvent(.jumpToConversation(convo))
                                }
                            }
                            channelOrNick = ""
                        }
                    } message: {
                        Text("Enter a channel name to join, or a nickname to send a message to.")
                    }
                }
            }
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
                case .popNavigation:
                    selection = nil
                case .jumpToChannel(let channel):
                    selection = .channel(channel)
                case .jumpToConversation(let conversation):
                    selection = .conversation(conversation)
                }
            }
        }
        .sheet(isPresented: $showingAppSettings) {
            SettingsView()
        }
    }
}

#Preview(traits: .modifier(PreviewData())) {
    MainNavigation()
}
