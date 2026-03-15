//
//  UserList.swift
//  Parlor
//
//  Created by Daniel Watson on 11/19/24.
//

import SwiftUI

struct UserList: View {
    @Environment(IRCClient.self) var client
    @Environment(IRCChannel.self) var channel

    @AppStorage("showHostmasks") private var showHostmasks = true
    @AppStorage("showRealnames") private var showRealnames = true
    @AppStorage("showAccounts") private var showAccounts = true

    @State private var selectedUser: IRCUser.ID? = nil

    func userDescription(_ user: IRCUser) -> String {
        var description: [String] = []
        if showRealnames, !user.realname.isEmpty {
            description.append(user.realname)
        }
        if showAccounts, let acct = user.acctname {
            description.append("@\(acct)")
        }
        if showHostmasks {
            description.append("\(user.username)@\(user.hostname)")
        }
        return description.joined(separator: " • ")
    }

    var body: some View {
        List(channel.sortedUsers, selection: $selectedUser) { user in
            HStack(alignment: .firstTextBaseline) {
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(.green)
                VStack(alignment: .leading) {
                    Text(user.nickname)
                    if showHostmasks || showRealnames || showAccounts {
                        Text(userDescription(user))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tag(user.id)
            .listRowSeparator(.hidden)
        }
        .contextMenu(forSelectionType: IRCUser.ID.self) { users in
            Button("Message") {
                startConversation(users)
            }
        } primaryAction: { users in
            startConversation(users)
        }
        #if os(macOS)
            .listStyle(.inset)
        #else
            .listStyle(.inset)
        #endif
    }

    func startConversation(_ users: Set<IRCUser.ID>) {
        if let nickname = users.first, nickname != client.nickname,
            let user = client.getUser(nickname),
            let conversation = client.getConversation(user, create: true)
        {
            client.appEvent(.jumpToConversation(conversation))
        }
    }
}

#Preview(traits: .modifier(PreviewData())) {
    UserList()
}
