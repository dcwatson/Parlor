//
//  PreviewData.swift
//  Parlor
//
//  Created by Daniel Watson on 11/27/24.
//

import SwiftUI

struct PreviewEnvironment {
    var client: IRCClient
    var channel: IRCChannel
}

struct PreviewData: PreviewModifier {
    static func makeSharedContext() async throws -> PreviewEnvironment {
        let client = IRCClient()
        let channel = IRCChannel("#avaraline", topic: "Testing is good!")
        let beth = IRCUser("Beth!parlor@localhost.localdomain")
        let joey = IRCUser("Joey!parlor@localhost.localdomain")
        client.users = [beth, joey]
        channel.users = client.users
        channel.privmsg(
            .init(
                hostmask: beth.hostmask,
                message: "Baltimore Orioles, number one!",
                tags: [
                    .init(key: "time", value: "2020-02-28T12:54:00.000Z")
                ]
            ),
            sendEvent: false
        )
        channel.privmsg(
            .init(
                hostmask: joey.hostmask,
                message: "Shut up Beth",
                tags: [
                    .init(key: "time", value: "2020-02-28T17:26:00.000Z")
                ]
            ),
            sendEvent: false
        )
        channel.privmsg(
            .init(
                hostmask: joey.hostmask,
                message: "Second grouped line with a lot more text in it (hopefully wrapping to second line)",
                tags: [
                    .init(key: "time", value: "2020-02-28T17:26:30.000Z")
                ]
            ),
            sendEvent: false
        )
        client.channels = [channel]
        client.log = [
            IRCLine("NICK", params: ["Beth"]),
            IRCLine("USER", params: ["parlor", "0", "*", "Parlor User"]),
            IRCLine("PING", params: ["3205B4D3"]),
        ]
        client.log[2].outgoing = false
        client.conversations = [
            .init(user: beth),
        ]
        return PreviewEnvironment(client: client, channel: channel)
    }

    func body(content: Content, context: PreviewEnvironment) -> some View {
        content
            .environment(context.client)
            .environment(context.channel)
    }
}
