//
//  ConnectForm.swift
//  Parlor
//
//  Created by Daniel Watson on 11/23/24.
//

import SwiftUI

struct ConnectForm: View {
    @Environment(IRCClient.self) var client

    @AppStorage("address") private var address: String = "localhost"
    @AppStorage("port") private var port: String = "6667"
    @AppStorage("tls") private var tls: Bool = false
    @AppStorage("nickname") private var nickname = "Beth"
    @AppStorage("username") private var username = "parlor"
    @AppStorage("realname") private var realname = "Parlor User"

    @State private var password: String = ""

    var body: some View {
        Form {
            Section {
                TextField("Address", text: $address)
                TextField("Port", text: $port)
                Toggle("Use TLS", isOn: $tls)
            }

            Section {
                TextField("Nickname", text: $nickname)
                TextField("Username", text: $username)
                TextField("Real name", text: $realname)
                SecureField("Password", text: $password)
            }

            Button("Connect") {
                client.nickname = nickname
                client.username = username
                client.realname = realname
                client.connect(address, port: UInt16(port)!, useTLS: tls)
            }
        }
    }
}

#Preview(traits: .modifier(PreviewData())) {
    ConnectForm()
}
