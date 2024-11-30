//
//  IRCCommand.swift
//  Parlor
//
//  Created by Daniel Watson on 11/21/24.
//

enum IRCCommand {
    case ping(token: String? = nil)
    case pong(token: String? = nil)

    case pass(password: String)
    case nick(nickname: String)
    case user(user: String, realname: String)
    case oper(name: String, password: String)
    case quit(message: String)
    case part(channel: String)
    case who(mask: String)

    case privmsg(target: String, message: String)
    case notice(target: String, message: String)

    case capLS(version: Int)
    case capREQ(capabilities: IRCCapabilities)
    case capEND

    case join(channel: String, password: String? = nil)

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

        case .join(let channel, let password):
            var params = [channel]
            if let password { params.append(password) }
            return .init("JOIN", params: params)

        case .custom(let command, let params):
            return .init(command, params: params)
        }
    }
}
