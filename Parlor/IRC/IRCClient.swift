//
//  IRCClient.swift
//  Parlor
//
//  Created by Daniel Watson on 11/20/24.
//

import Combine
import SwiftUI

let REQUEST_CAPS: IRCCapabilities = [
    "away-notify",
    "batch",
    "echo-message",
    "extended-join",
    "labeled-response",
    "message-tags",
    "server-time",
    "standard-replies",
    "userhost-in-names",
].map { IRCCapability($0) }

enum AppEvent {
    case popNavigation
    case jumpToChannel(IRCChannel)
    case jumpToConversation(IRCConversation)
}

enum IRCEvent {
    case connected
    case disconnected

    case line(IRCLine)
    case error(Error)
    case serverError(String)

    case welcome(String)
    case channelList(String, Int, String)
    case channelListEnd

    case nickChanged(IRCUser, String)
    case userQuit(IRCUser, String?)

    case app(AppEvent)
}

@Observable class IRCClient {
    enum Target {
        case channel(IRCChannel)
        case user(IRCUser)
        case unspecified
    }

    var nickname: String = "Beth"
    var realname: String = "Parlor User"
    var username: String = "parlor"

    var connected: Bool = false
    var supports: [String: String] = [:]

    var availableCapabilities: IRCCapabilities = .init()
    var capabilities: IRCCapabilities = .init()
    var log: [IRCLine] = []
    var users: [IRCUser] = []
    var channels: [IRCChannel] = []
    var conversations: [IRCConversation] = []

    var supportsTags: Bool { capabilities.has("message-tags") }

    @ObservationIgnored var events: AnyPublisher<IRCEvent, Never>

    @ObservationIgnored private var conn: IRCConnection = .init()
    @ObservationIgnored private var lineStream: AnyCancellable? = nil
    @ObservationIgnored private var stateStream: AnyCancellable? = nil
    @ObservationIgnored private var eventStream = PassthroughSubject<IRCEvent, Never>()

    @ObservationIgnored @AppStorage("consoleLimit") private var consoleLimit = 10000

    init() {
        events = eventStream.eraseToAnyPublisher()
        lineStream = conn.lines.sink { line in
            self.lineReceived(line)
        }
        stateStream = conn.$state.sink { state in
            self.connectionStateChanged(state)
        }
    }

    func connect(_ host: String, port: UInt16 = 6667, useTLS: Bool = false) {
        conn.connect(host, port: port, useTLS: useTLS)
    }

    func send(_ command: IRCCommand) {
        let line = command.toLine()
        conn.write(line, includeTags: supportsTags)
        logLine(line)
    }

    private func logLine(_ line: IRCLine) {
        while log.count >= consoleLimit {
            log.removeFirst()
        }
        log.append(line)
    }

    func appEvent(_ event: AppEvent) {
        eventStream.send(.app(event))
    }

    func getUser<S: StringProtocol>(_ nickOrMask: S?, create: Bool = false) -> IRCUser? {
        guard let nickOrMask else { return nil }

        let newUser = IRCUser(nickOrMask)
        if let user = users.first(where: {
            $0.nickname.lowercased() == newUser.nickname.lowercased()
        }) {
            return user
        }

        if create {
            users.append(newUser)
            users.sort(by: { $0.nickname < $1.nickname })
            return newUser
        }

        return nil
    }

    func getChannel(_ name: String?, create: Bool = false) -> IRCChannel? {
        guard let name else { return nil }

        if let channel = channels.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return channel
        }

        if create {
            let channel = IRCChannel(name)
            channels.append(channel)
            channels.sort(by: { $0.name < $1.name })
            return channel
        }

        return nil
    }

    func getConversation(_ user: IRCUser, create: Bool = false) -> IRCConversation? {
        if let convo = conversations.first(where: { $0.user == user }) {
            return convo
        }

        if create {
            let convo = IRCConversation(user: user)
            conversations.append(convo)
            return convo
        }

        return nil
    }

    func removeConversation(_ conversation: IRCConversation) {
        conversations.removeAll(where: { $0 == conversation })
    }

    func getTarget(_ target: String?) -> Target {
        guard let target, target != "*" else { return .unspecified }
        if target.hasPrefix("#"), let channel = getChannel(target) {
            return .channel(channel)
        } else if let user = getUser(target, create: true) {
            return .user(user)
        }
        return .unspecified
    }

    private func connectionStateChanged(_ state: IRCConnection.State) {
        switch state {
        case .connected:
            send(.capLS(version: 302))
            send(.nick(nickname: nickname))
            send(.user(user: username, realname: realname))
            connected = true
            eventStream.send(.connected)
        case .disconnected:
            connected = false
            eventStream.send(.disconnected)
        default:
            break
        }
    }

    private func lineReceived(_ line: IRCLine) {
        // Ignore RPL_LIST items for now, since there can be thousands of them.
        if line.command != "322" {
            logLine(line)
        }
        eventStream.send(.line(line))

        if let number = Int(line.command) {
            if let reply = IRCReply(rawValue: number) {
                handleReply(reply, line: line)
            } else if let err = IRCError(rawValue: number) {
                handleError(err, line: line)
            } else {
                print("UNKNOWN NUMERIC", line)
            }
        } else {
            handleCommand(line.command.uppercased(), line: line)
        }
    }

    private func handleCommand(_ command: String, line: IRCLine) {
        switch command {
        case "PING":
            send(.pong(token: line.params.first))
        case "NICK":
            guard let user = getUser(line.source), let newNick = line[0] else { return }
            user.nickname = newNick
            eventStream.send(.nickChanged(user, newNick))
        case "QUIT":
            guard let user = getUser(line.source) else { return }
            for channel in channels {
                channel.part(user, sendEvent: false)
            }
            eventStream.send(.userQuit(user, line.message))
        case "JOIN":
            guard let user = getUser(line.source, create: true),
                let channel = getChannel(line[0], create: true)
            else { return }
            channel.join(user, sendEvent: user.nickname != nickname)
            if user.nickname == nickname {
                send(.who(mask: channel.name))
                eventStream.send(.app(.jumpToChannel(channel)))
            }
        case "PART":
            guard let user = getUser(line.source), let channel = getChannel(line[0]) else { return }
            channel.part(user, reason: line[1])
            if user.nickname == nickname {
                channels.removeAll(where: { $0.name == channel.name })
            }
        case "TOPIC":
            if let channel = getChannel(line[0]), let topic = line.message {
                channel.topic = topic
            }
        case "ERROR":
            guard let msg = line[0] else { return }
            eventStream.send(.serverError(msg))
        case "PRIVMSG", "NOTICE":
            guard let user = getUser(line.source) else { return }
            let message = IRCMessage(user: user, message: line.message, tags: line.tags)
            switch getTarget(line[0]) {
            case .channel(let channel):
                channel.privmsg(message)
            case .user(let toUser):
                if toUser.nickname == nickname, let convo = getConversation(user, create: true) {
                    convo.privmsg(message)
                } else if user.nickname == nickname,
                    let convo = getConversation(toUser, create: true)
                {
                    // These are echos of our own PRIVMSG
                    convo.privmsg(message)
                }
            case .unspecified:
                print("PRIVMSG with invalid target")
            }
        case "CAP":
            guard let newNick = line[0], let subcommand = line[1] else { return }
            if newNick != "*" { nickname = newNick }
            switch subcommand.uppercased() {
            case "ACK":
                if let caps = line.message {
                    capabilities.ack(.init(caps))
                }
                send(.capEND)
            case "LS":
                if let caps = line.message {
                    availableCapabilities.ack(.init(caps))
                }
                if line[2] != "*" {
                    send(.capREQ(capabilities: REQUEST_CAPS.intersection(availableCapabilities)))
                }
            default:
                break
            }
        default:
            break
        }
    }

    private func handleReply(_ reply: IRCReply, line: IRCLine) {
        switch reply {
        case .welcome:
            eventStream.send(.welcome(line[0] ?? ""))
        case .isupport:
            for (idx, param) in line.params.enumerated() {
                if (idx == 0) || (idx >= line.params.count - 1) { continue }
                let parts = param.split(separator: "=", maxSplits: 1)
                supports[String(parts[0])] = parts.count > 1 ? String(parts[1]) : ""
            }
        case .namreply:
            guard
                let channel = getChannel(line[2]),
                let names = line[3]
            else { return }
            for name in names.split(separator: " ") {
                let channelModes = name.prefix(while: { "~&@%+".contains($0) })
                if let user = getUser(name[channelModes.endIndex...], create: true) {
                    channel.join(user, sendEvent: false)
                }
            }
        case .whoreply:
            if let user = getUser(line[5]) {
                if let username = line[2] { user.username = username }
                if let hostname = line[3] { user.hostname = hostname }
                if let realname = line.message { user.realname = realname }
            }
        case .list:
            if let channelName = line[1], let count = Int(line[2] ?? "0") {
                eventStream.send(.channelList(channelName, count, line[3] ?? ""))
            }
        case .listend:
            eventStream.send(.channelListEnd)
        case .topic:
            if let channel = getChannel(line[1]), let topic = line.message {
                channel.topic = topic
            }
        default:
            break
        }
    }

    private func handleError(_ err: IRCError, line: IRCLine) {
        switch err {
        case .nicknameinuse:
            nickname = nickname + "_"
            send(.nick(nickname: nickname))
        default:
            break
        }
    }
}
