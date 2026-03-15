//
//  IRCAuthentication.swift
//  Parlor
//
//  Created by Daniel Watson on 3/14/26.
//

import Foundation

extension String {
    fileprivate func base64EncodedString() -> String {
        Data(self.utf8).base64EncodedString()
    }

    fileprivate func base64DecodedString() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}

protocol IRCAuthentication {
    func clientConnected(client: IRCClient)
    func clientCapabilities(client: IRCClient) throws
    func clientAuthenticate(client: IRCClient, line: IRCLine) throws
    func clientReply(client: IRCClient, reply: IRCReply, line: IRCLine)
    func clientError(client: IRCClient, error: IRCError, line: IRCLine)
}

extension IRCAuthentication {
    func clientConnected(client: IRCClient) {}

    func clientCapabilities(client: IRCClient) throws {
        // By default CAP END is sent after capabilities are ACKed.
        client.send(.capEND)
    }

    func clientAuthenticate(client: IRCClient, line: IRCLine) throws {}

    func clientReply(client: IRCClient, reply: IRCReply, line: IRCLine) {}

    func clientError(client: IRCClient, error: IRCError, line: IRCLine) {}
}

class NoAuth: IRCAuthentication {}

class PasswordAuth: IRCAuthentication {
    func clientConnected(client: IRCClient) {
        if !client.password.isEmpty {
            client.send(.pass(password: client.password))
        }
    }
}

class SASLAuth: IRCAuthentication {
    let allowPlain: Bool

    enum Mechanism: String {
        case none = ""
        case scramSha256 = "SCRAM-SHA-256"
        case scramSha1 = "SCRAM-SHA-1"
        case plain = "PLAIN"
    }

    enum Error: Swift.Error, LocalizedError {
        case saslNotSupported
        case noSupportedMechanism
        case invalidAuthMessage
        case invalidState
    }

    private var scram: SCRAM?
    private var mechanism: Mechanism = .none

    init(allowPlain: Bool = true) {
        self.allowPlain = allowPlain
    }

    func clientCapabilities(client: IRCClient) throws {
        // Ensure SASL authentication is available and negotiated.
        guard let supports = client.availableCapabilities.get("sasl"),
            client.capabilities.has("sasl")
        else {
            throw Error.saslNotSupported
        }

        if supports.values.contains("SCRAM-SHA-256") {
            mechanism = .scramSha256
            scram = SCRAM(username: client.username, password: client.password, algorithm: .sha256)
        } else if supports.values.contains("SCRAM-SHA-1") {
            mechanism = .scramSha1
            scram = SCRAM(username: client.username, password: client.password, algorithm: .sha1)
        } else if allowPlain && supports.values.contains("PLAIN") {
            mechanism = .plain
        } else {
            throw Error.noSupportedMechanism
        }

        client.send(.authenticate(data: mechanism.rawValue))
    }

    func clientAuthenticate(client: IRCClient, line: IRCLine) throws {
        switch mechanism {
        case .none:
            throw Error.noSupportedMechanism
        case .scramSha256, .scramSha1:
            guard let scram else { throw Error.invalidState }
            switch scram.status {
            case .notStarted:
                let message = try scram.generateClientFirstMessage()
                client.send(.authenticate(data: message.base64EncodedString()))
            case .awaitingServerFirst:
                guard let message = line.message?.base64DecodedString() else {
                    throw Error.invalidAuthMessage
                }

                try scram.parseServerFirstMessage(message)

                let clientFinal = try scram.generateClientFinalMessage()
                client.send(.authenticate(data: clientFinal.base64EncodedString()))
            case .awaitingServerFinal:
                guard let message = line.message?.base64DecodedString() else {
                    throw Error.invalidAuthMessage
                }

                try scram.parseServerFinalMessage(message)
                client.send(.authenticate(data: "+"))
            case .complete:
                break
            }
        case .plain:
            if line.message == "+" {
                let auth = "\(client.username)\0\(client.username)\0\(client.password)"
                client.send(.authenticate(data: auth.base64EncodedString()))
            }
        }
    }

    func clientReply(client: IRCClient, reply: IRCReply, line: IRCLine) {
        switch reply {
        case .saslsuccess:
            client.send(.capEND)
        default:
            break
        }
    }
}
