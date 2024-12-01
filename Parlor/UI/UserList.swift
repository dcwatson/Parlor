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

    @State private var selectedUser: IRCUser.ID? = nil

    var body: some View {
        List(channel.users, selection: $selectedUser) { user in
            HStack(alignment: .firstTextBaseline) {
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(.green)
                VStack(alignment: .leading) {
                    Text(user.nickname)
                    Text("\(user.username)@\(user.hostname)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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
