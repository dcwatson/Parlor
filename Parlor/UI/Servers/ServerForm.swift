//
//  ServerForm.swift
//  Parlor
//
//  Created by Daniel Watson on 4/1/26.
//

import SwiftUI
import SwiftData

struct ServerForm: View {
    @Environment(Parlor.self) var parlor

    @Bindable var server: Server

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $server.name)
                Toggle("Update when provided by server", isOn: $server.updateName)
            }

            Section {
                TextField("Address", text: $server.address)
                TextField("Port", value: $server.port, formatter: NumberFormatter())
                Toggle("Use TLS", isOn: $server.useTLS)
            }

            Section {
                TextField("Nickname", text: $server.nickname)
                TextField("Ident", text: $server.identity)
                TextField("Real name", text: $server.realname)
            }

            Section {
                Picker("Authentication", selection: $server.authMethod) {
                    Text("None").tag(AuthMethod.none)
                    Text("Server Password (PASS)").tag(AuthMethod.serverPassword)
                    Text("SASL (SCRAM-SHA-*, PLAIN)").tag(AuthMethod.saslAny)
                    Text("SASL (SCRAM only)").tag(AuthMethod.saslScram)
                }
                .pickerStyle(.inline)
                //.padding(.top, 12)

                Group {
                    if server.authMethod != .none {
                        if server.authMethod != .serverPassword {
                            TextField("Username", text: $server.username)
                        }
                        SecureField("Password", text: $server.password)
                    }
                }
            }

            /*
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
             */
        }
        .onChange(of: server.useTLS) {
            if server.useTLS && server.port == 6667 {
                server.port = 6697
            } else if !server.useTLS && server.port == 6697 {
                server.port = 6667
            }
        }
    }
}

struct ServerTabs: View {
    @Bindable var server: Server

    var body: some View {
        TabView {
            Tab("Connection", systemImage: "gear") {
                ServerForm(server: server)
            }
            Tab("Notifications", systemImage: "bell") {
                Text("Notifications settings…")
            }
        }
    }
}

#Preview(traits: .modifier(PreviewData())) {
    @Previewable @State var server: Server = Server()

    NavigationSplitView {

    } detail: {
        ServerTabs(server: server)
            .scenePadding()
    }
}
