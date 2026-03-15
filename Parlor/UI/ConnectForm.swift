//
//  ConnectForm.swift
//  Parlor
//
//  Created by Daniel Watson on 11/23/24.
//

import SwiftUI

enum AuthMethod: String, CaseIterable, Identifiable {
    case none
    case serverPassword
    case saslAny
    case saslScram

    var id: Self { self }
}

struct ConnectForm: View {
    @Environment(IRCClient.self) var client

    @AppStorage("address") private var address: String = "localhost"
    @AppStorage("port") private var port: String = "6667"
    @AppStorage("tls") private var tls: Bool = false
    @AppStorage("nickname") private var nickname = NSUserName()
    @AppStorage("ident") private var ident = "parlor"
    @AppStorage("realname") private var realname = NSFullUserName()
    @AppStorage("username") private var username = NSUserName()
    @AppStorage("password") private var password: String = ""
    @AppStorage("authMethod") private var authMethod: AuthMethod = .none

    var body: some View {
        Form {
            Section {
                TextField("Address", text: $address)
                TextField("Port", text: $port)
                Toggle("Use TLS", isOn: $tls)
            }

            Section {
                TextField("Nickname", text: $nickname)
                TextField("Ident", text: $ident)
                TextField("Real name", text: $realname)
            }

            Section {
                Picker("Authentication", selection: $authMethod) {
                    Text("None").tag(AuthMethod.none)
                    Text("Server Password (PASS)").tag(AuthMethod.serverPassword)
                    Text("SASL (SCRAM-SHA-*, PLAIN)").tag(AuthMethod.saslAny)
                    Text("SASL (SCRAM only)").tag(AuthMethod.saslScram)
                }
                .pickerStyle(.inline)
                //.padding(.top, 12)

                Group {
                    if authMethod != .none {
                        if authMethod != .serverPassword {
                            TextField("Username", text: $username)
                        }
                        SecureField("Password", text: $password)
                    }
                }
            }

            Button("Connect") {
                client.nickname = nickname
                client.identity = ident
                client.realname = realname
                client.username = username
                client.password = password
                switch authMethod {
                case .none:
                    client.auth = NoAuth()
                case .serverPassword:
                    client.auth = PasswordAuth()
                case .saslAny:
                    client.auth = SASLAuth(allowPlain: true)
                case .saslScram:
                    client.auth = SASLAuth(allowPlain: false)
                }
                client.connect(address, port: UInt16(port)!, useTLS: tls)
            }
        }
        .onChange(of: tls) {
            if tls && port == "6667" {
                port = "6697"
            } else if !tls && port == "6697" {
                port = "6667"
            }
        }
    }
}

#Preview(traits: .modifier(PreviewData())) {
    ConnectForm()
}
