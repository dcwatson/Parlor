//
//  IRCModels.swift
//  Parlor
//
//  Created by Daniel Watson on 12/1/24.
//

import SwiftUI

@MainActor
@Observable
final class IRCUser: Identifiable, Hashable {
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

@MainActor
@Observable
class IRCMessage: Identifiable, Equatable {
    var id: String
    var hostmask: String
    var nickname: String
    var acctname: String?
    var message: String
    var tags: IRCTags
    var timestamp: Date

    var imageUrls: [URL] = []
    var needsUrlDetection: Bool = true

    static func == (lhs: IRCMessage, rhs: IRCMessage) -> Bool {
        lhs.id == rhs.id
    }

    static let linkDetector: NSDataDetector = {
        return try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    }()

    // These are set when adding to a channel or conversation.
    var nickChanged: Bool = true
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

    func detectUrls() async {
        guard needsUrlDetection else { return }

        imageUrls = await withTaskGroup(of: Int?.self) { group in
            var allUrls: [URL] = []

            for match in Self.linkDetector.matches(
                in: message,
                options: [],
                range: NSRange(message.startIndex..<message.endIndex, in: message)
            ) {
                guard let range = Range(match.range, in: message) else { continue }
                if let url = URL(string: String(message[range])) {
                    allUrls.append(url)
                    let index = allUrls.count - 1
                    group.addTask {
                        if let ct = await fetchContentType(url) {
                            if ct.hasPrefix("image/") && !ct.hasSuffix("xml") {
                                // Tasks return an index so we can retain link order
                                return index
                            }
                        }
                        return nil
                    }
                }
            }

            var indices: [Int] = []
            for await idx in group {
                if let idx { indices.append(idx) }
            }

            return indices.sorted().map { allUrls[$0] }
        }

        needsUrlDetection = false
    }
}

@MainActor
@Observable
final class IRCChannel: Identifiable, Hashable {
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

    @ObservationIgnored var events = Streamer<Event>()
    @ObservationIgnored @AppStorage("messageLimit") private var messageLimit = 1000

    init(_ name: String, topic: String = "") {
        self.name = name
        self.topic = topic
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
            events.broadcast(.userJoined(user))
        }
    }

    func part(_ user: IRCUser, reason: String? = nil, sendEvent: Bool = true) {
        users.removeAll(where: { $0.nickname == user.nickname })
        if sendEvent {
            events.broadcast(.userParted(user, reason))
        }
    }

    func privmsg(_ message: IRCMessage, sendEvent: Bool = true) {
        if let lastMessage = messages.last {
            message.nickChanged = lastMessage.nickname != message.nickname
            message.dateChanged = message.timestamp.dateChanged(since: lastMessage.timestamp)
            message.timeChanged = message.timestamp.timeChanged(since: lastMessage.timestamp)
        }
        messages.append(message)
        while messages.count > messageLimit {
            messages.removeFirst()
        }
        messages.first!.nickChanged = true
        messages.first!.dateChanged = true
        messages.first!.timeChanged = true
        if sendEvent {
            events.broadcast(.message(message))
        }
    }
}

@MainActor
@Observable
final class IRCConversation: Identifiable, Hashable {
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
