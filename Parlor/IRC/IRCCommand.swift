//
//  IRCCommand.swift
//  Parlor
//
//  Created by Daniel Watson on 11/21/24.
//

import Foundation

let isoDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    formatter.timeZone = .gmt
    return formatter
}()

enum ChatHistorySince {
    case timestamp(Date)
    case msgid(String)
    case all
    
    var stringValue: String {
        switch self {
        case .timestamp(let date):
            return "timestamp=" + isoDateFormatter.string(from: date)
        case .msgid(let msgid):
            return "msgid=" + msgid
        case .all:
            return "*"
        }
    }
}

enum ChatHistoryCommand {
    case before(ChatHistorySince)
    case after(ChatHistorySince)
    case latest
    
    func toParams(_ target: String, limit: Int) -> [String] {
        switch self {
        case .before(let since):
            return ["BEFORE", target, since.stringValue, String(limit)]
        case .after(let since):
            return ["AFTER", target, since.stringValue, String(limit)]
        case .latest:
            return ["LATEST", target, "*", String(limit)]
        }
    }
}

enum IRCCommand {
    case ping(token: String? = nil)
    case pong(token: String? = nil)

    case pass(password: String)
    case nick(nickname: String)
    case user(user: String, realname: String)
    case oper(name: String, password: String)
    case quit(message: String)
    case join(channel: String, password: String? = nil)
    case part(channel: String)
    case who(mask: String)
    case topic(channel: String, topic: String)

    case privmsg(target: String, message: String)
    case notice(target: String, message: String)

    case capLS(version: Int)
    case capREQ(capabilities: IRCCapabilities)
    case capEND

    case chathistory(target: String, command: ChatHistoryCommand, limit: Int)

    case custom(command: String, params: [String] = [])

    func toLine() -> IRCLine {
        switch self {
        case .ping(let token):
            guard let token else { return .init("PING") }
            return .init("PING", params: [token])
        case .pong(let token):
            guard let token else { return .init("PONG") }
            return .init("PONG", params: [token])

        case .pass(let password):
            return .init("PASS", params: [password])
        case .nick(let nickname):
            return .init("NICK", params: [nickname])
        case .user(let user, let realname):
            return .init("USER", params: [user, "0", "*", realname])
        case .oper(let name, let password):
            return .init("OPER", params: [name, password])
        case .quit(let message):
            return .init("QUIT", params: [message])
        case .who(let mask):
            return .init("WHO", params: [mask])
        case .part(let channel):
            return .init("PART", params: [channel])
        case .topic(let channel, let topic):
            return .init("TOPIC", params: [channel, topic])

        case .privmsg(let target, let message):
            return .init("PRIVMSG", params: [target, message])
        case .notice(let target, let message):
            return .init("NOTICE", params: [target, message])

        case .capLS(let version):
            return .init("CAP", params: ["LS", String(version)])
        case .capREQ(let capabilities):
            return .init("CAP", params: ["REQ", capabilities.stringValue])
        case .capEND:
            return .init("CAP", params: ["END"])

        case .chathistory(let target, let command, let limit):
            return .init("CHATHISTORY", params: command.toParams(target, limit: limit))

        case .join(let channel, let password):
            var params = [channel]
            if let password { params.append(password) }
            return .init("JOIN", params: params)

        case .custom(let command, let params):
            return .init(command, params: params)
        }
    }
}
