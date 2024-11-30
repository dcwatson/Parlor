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

    @State private var selectedUser: IRCUser? = nil

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
            .tag(user)
            .listRowSeparator(.hidden)
        }
        #if os(macOS)
            .listStyle(.inset)
            .contextMenu(forSelectionType: IRCUser.self) { users in
                Button("Message") {
                    startConversation(users)
                }
            } primaryAction: { users in
                startConversation(users)
            }
        #else
            .listStyle(.plain)
        #endif
    }

    func startConversation(_ users: Set<IRCUser>) {
        if let user = users.first, user.nickname != client.nickname,
            let conversation = client.getConversation(user, create: true)
        {
            client.appEvent(.jumpToConversation(conversation))
        }
    }
}

#Preview(traits: .modifier(PreviewData())) {
    UserList()
}
