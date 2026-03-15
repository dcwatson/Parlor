//
//  IRCAuthentication.swift
//  Parlor
//
//  Created by Daniel Watson on 3/14/26.
//

import Foundation

protocol IRCAuthentication {
    func clientConnected(client: IRCClient)
    func clientCapabilities(client: IRCClient)
    func clientAuthenticate(client: IRCClient, line: IRCLine)
    func clientReply(client: IRCClient, reply: IRCReply, line: IRCLine)
    func clientError(client: IRCClient, error: IRCError, line: IRCLine)
}

extension IRCAuthentication {
    func clientConnected(client: IRCClient) {}

    func clientCapabilities(client: IRCClient) {
        // By default CAP END is sent after capabilities are ACKed.
        client.send(.capEND)
    }

    func clientAuthenticate(client: IRCClient, line: IRCLine) {}
    func clientReply(client: IRCClient, reply: IRCReply, line: IRCLine) {}
    func clientError(client: IRCClient, error: IRCError, line: IRCLine) {}
}

class PasswordAuth: IRCAuthentication {
    func clientConnected(client: IRCClient) {
        if !client.password.isEmpty {
            client.send(.pass(password: client.password))
        }
    }
}

class SASLPlain: IRCAuthentication {
    func clientCapabilities(client: IRCClient) {
        // Ensure SASL PLAIN is available and was negotiated successfully.
        guard let supports = client.availableCapabilities.get("sasl"),
            supports.values.contains("PLAIN"),
            client.capabilities.has("sasl")
        else {
            // TODO: throw an error here
            print("SASL PLAIN auth not supported")
            return
        }
        client.send(.authenticate(data: "PLAIN"))
    }

    func clientAuthenticate(client: IRCClient, line: IRCLine) {
        if line[0] == "+" {
            let auth = Data("\(client.username)\0\(client.username)\0\(client.password)".utf8)
            client.send(.authenticate(data: auth.base64EncodedString()))
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
