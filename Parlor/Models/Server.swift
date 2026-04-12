//
//  Server.swift
//  Parlor
//
//  Created by Daniel Watson on 3/30/26.
//

import SwiftData
import Foundation

enum AuthMethod: String, CaseIterable, Identifiable, Codable {
    case none
    case serverPassword
    case saslAny
    case saslScram

    var id: String { self.rawValue }
}

@Model
final class Server {
    var name: String = "New Server"
    var updateName: Bool = true

    var address: String = "parlorirc.com"
    var port: UInt16 = 6667
    var useTLS: Bool = false

    var nickname: String = NSUserName()
    var identity: String = NSUserName()
    var realname: String = NSFullUserName()

    var authMethod: AuthMethod = AuthMethod.none
    var username: String = ""

    @Attribute(.allowsCloudEncryption)
    var password: String = ""

    init() {
    }

    @MainActor
    func makeAuth() -> IRCAuthentication {
        switch authMethod {
        case .none:
            return NoAuth()
        case .serverPassword:
            return PasswordAuth(password)
        case .saslAny:
            return SASLAuth(username: username, password: password)
        case .saslScram:
            return SASLAuth(username: username, password: password, allowPlain: false)
        }
    }
}
