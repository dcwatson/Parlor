//
//  IRCModels.swift
//  Parlor
//
//  Created by Daniel Watson on 12/1/24.
//

import Combine
import SwiftUI

@Observable class IRCUser: Identifiable, Hashable {
    var nickname: String
    var username: String
    var hostname: String
    var realname: String
    var acctname: String?

    var hostmask: String {
        "\(nickname)!\(username)@\(hostname)"
    }

    var id: String { nickname }

    init<S: StringProtocol>(_ hostmask: S) {
        let reader = StringReader(hostmask)
        self.nickname = reader.readUntil("!")
        self.username = reader.readUntil("@")
        self.hostname = reader.read()
        self.realname = ""
    }

    init(
        nickname: String,
        username: String = "",
        hostname: String = "",
        realname: String = "",
        acctname: String? = nil
    ) {
        self.nickname = nickname
        self.username = username
        self.hostname = hostname
        self.realname = realname
        self.acctname = acctname
    }

    static func == (lhs: IRCUser, rhs: IRCUser) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@Observable class IRCMessage: Identifiable {
    var id: String
    var hostmask: String
    var nickname: String
    var acctname: String?
    var message: String
    var tags: IRCTags
    var timestamp: Date

    // var type: Type (.message, .notice, .join, .part, etc...)

    // These are set when adding to a channel or conversation.
    var dateChanged: Bool = false
    var timeChanged: Bool = false

    var maybeTimeString: String {
        timeChanged ? timeFormatter.string(from: timestamp) : ""
    }

    init(hostmask: String, message: String, tags: IRCTags) {
        self.hostmask = hostmask
        self.nickname = StringReader(hostmask).readUntil("!")
        self.acctname = tags["account"]
        self.message = message
        self.tags = tags
        self.id = tags["msgid"] ?? UUID().uuidString
        if let time = tags["time"], let date = isoDateFormatter.date(from: time) {
            self.timestamp = date
        } else {
            self.timestamp = .now
        }
    }
}

@Observable class IRCChannel: Identifiable, Hashable {
    enum Event {
        case userJoined(IRCUser)
        case userParted(IRCUser, String?)
        case message(IRCMessage)
    }

    var name: String
    var topic: String
    var users: [IRCUser] = []
    var messages: [IRCMessage] = []
    //var log: [IRCLine] = []

    var id: String { name }
    var sortedUsers: [IRCUser] {
        users.sorted(by: { $0.nickname.lowercased() < $1.nickname.lowercased() })
    }

    @ObservationIgnored var events: AnyPublisher<Event, Never>
    @ObservationIgnored private var eventStream = PassthroughSubject<Event, Never>()
    @ObservationIgnored @AppStorage("messageLimit") private var messageLimit = 1000

    init(_ name: String, topic: String = "") {
        self.name = name
        self.topic = topic
        self.events = eventStream.eraseToAnyPublisher()
    }

    static func == (lhs: IRCChannel, rhs: IRCChannel) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func join(_ user: IRCUser, sendEvent: Bool = true) {
        if users.contains(user) { return }
        users.append(user)
        if sendEvent {
            eventStream.send(.userJoined(user))
        }
    }

    func part(_ user: IRCUser, reason: String? = nil, sendEvent: Bool = true) {
        users.removeAll(where: { $0.nickname == user.nickname })
        if sendEvent {
            eventStream.send(.userParted(user, reason))
        }
    }

    func privmsg(_ message: IRCMessage, sendEvent: Bool = true) {
        if let lastMessage = messages.last {
            message.dateChanged = message.timestamp.dateChanged(since: lastMessage.timestamp)
            message.timeChanged = message.timestamp.timeChanged(since: lastMessage.timestamp)
        }
        messages.append(message)
        while messages.count > messageLimit {
            messages.removeFirst()
        }
        messages.first!.dateChanged = true
        messages.first!.timeChanged = true
        if sendEvent {
            eventStream.send(.message(message))
        }
    }
}

@Observable class IRCConversation: Identifiable, Hashable {
    var user: IRCUser
    var messages: [IRCMessage] = []

    @ObservationIgnored @AppStorage("messageLimit") private var messageLimit = 1000

    init(user: IRCUser) {
        self.user = user
    }

    func privmsg(_ message: IRCMessage) {
        messages.append(message)
        while messages.count > messageLimit {
            messages.removeFirst()
        }
    }

    static func == (lhs: IRCConversation, rhs: IRCConversation) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
