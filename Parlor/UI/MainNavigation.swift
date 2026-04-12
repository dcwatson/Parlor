//
//  MainNavigation.swift
//  Parlor
//
//  Created by Daniel Watson on 11/19/24.
//

import SwiftUI

@MainActor
enum NavSelection: Hashable {
    case console
    case channels
    case serverInfo
    case settings
    case channel(IRCChannel)
    case conversation(IRCConversation)
}

struct ChannelNavItem: View {
    let channel: IRCChannel
    let number: Int

    var body: some View {
        HStack {
            Text(channel.name)
            Spacer()
            Text("⌘\(number)")
                .foregroundStyle(.secondary)
                .font(.caption)
            /*
            Text(String(channel.users.count))
                .foregroundStyle(.secondary)
                .font(.subheadline)
             */
        }
    }
}

struct MainNavigation: View {
    //@Environment(\.modelContext) var modelContext
    @Environment(IRCClient.self) var client

    @AppStorage("showServerInfo") private var showServerInfo = true

    @State private var selection: NavSelection? = nil
    @State private var showingAppSettings: Bool = false
    @State private var showingJoinAlert: Bool = false
    @State private var showingNicknameAlert: Bool = false
    @State private var showingError: Bool = false
    @State private var lastError: String? = nil
    @State private var channelOrNick: String = ""
    @State private var realname: String = ""

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

                Label("Settings", systemImage: "gear")
                    .tag(NavSelection.settings)

                if !client.channels.isEmpty {
                    Section("Channels") {
                        ForEach(client.channels.enumerated(), id: \.offset) { index, channel in
                            ChannelNavItem(channel: channel, number: index + 1)
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
            case .settings:
                ServerTabs(server: client.server)
            case .channel(let channel):
                ChannelView()
                    .environment(channel)
                    //.focusedSceneValue(channel)
            case .conversation(let conversation):
                ConversationView()
                    .environment(conversation)
            }
        }
        .stream(client.events) { event in
            switch event {
            case .ready:
                if let serverName = client.supports["NETWORK"], client.server.updateName {
                    client.server.name = serverName
                }
            case .serverError(let msg):
                lastError = msg
                showingError = true
            case .app(let appEvent):
                switch appEvent {
                case .popNavigation:
                    selection = nil
                case .jumpToChannel(let channel):
                    selection = .channel(channel)
                case .jumpToConversation(let conversation):
                    selection = .conversation(conversation)
                case .joinCommand:
                    showingJoinAlert = true
                default:
                    break
                }
            default:
                break
            }
        }
        .sheet(isPresented: $showingAppSettings) {
            SettingsView()
        }
        .alert("Error", isPresented: $showingError, presenting: lastError) { err in
            Button("OK") {}
        } message: { err in
            Text(err)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    channelOrNick = client.nickname
                    realname = client.realname
                    showingNicknameAlert = true
                } label: {
                    Label("Nickname", systemImage: "person.text.rectangle")
                }
                .alert("Change Nickname", isPresented: $showingNicknameAlert) {
                    TextField("New nickname", text: $channelOrNick)
                    if client.capabilities.has("setname") {
                        TextField("New realname", text: $realname)
                    }
                    Button("Cancel", role: .cancel) {}
                    Button("OK") {
                        if !channelOrNick.isEmpty, channelOrNick != client.nickname {
                            client.nickname = channelOrNick
                            client.send(.nick(nickname: channelOrNick))
                        }
                        if client.capabilities.has("setname"), !realname.isEmpty,
                            realname != client.realname
                        {
                            client.send(.setname(realname: realname))
                        }
                        channelOrNick = ""
                        realname = ""
                    }
                }

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
    }
}

#Preview(traits: .modifier(PreviewData())) {
    MainNavigation()
}
