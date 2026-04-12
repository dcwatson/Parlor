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
    var parlor: Parlor
}

struct PreviewData: PreviewModifier {
    static func makeSharedContext() async throws -> PreviewEnvironment {
        let client = IRCClient(Server())
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
                message: "Second grouped line with a **lot more** text in it (hopefully wrapping to second line) and an image! https://temp.io/crvxabv9pxdw/view/alsalsadiol.jpg",
                tags: [
                    .init(key: "time", value: "2020-02-28T17:26:30.000Z")
                ]
            ),
            sendEvent: false
        )
        client.channels = [channel]
        let batch = IRCBatch(name: "asdf", type: "chathistory", params: ["#parlor"])
        batch.lines = [
            .init(
                "PRIVMSG",
                params: ["#parlor", "Baltimore Orioles, number one!"],
                source: beth.hostmask
            ),
            .init("PRIVMSG", params: ["#parlor", "Shut up Beth"], source: joey.hostmask),
        ]
        client.log = [
            .line(IRCLine("NICK", params: ["Beth"])),
            .line(IRCLine("USER", params: ["parlor", "0", "*", "Parlor User"])),
            .line(IRCLine("PING", params: ["3205B4D3"], outgoing: false)),
            .batch(batch),
        ]
        client.conversations = [
            .init(user: beth),
        ]
        let parlor = Parlor()
        return PreviewEnvironment(client: client, channel: channel, parlor: parlor)
    }

    func body(content: Content, context: PreviewEnvironment) -> some View {
        content
            .environment(context.parlor)
            .environment(context.client)
            .environment(context.channel)
    }
}
