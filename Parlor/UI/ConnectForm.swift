//
//  ConnectForm.swift
//  Parlor
//
//  Created by Daniel Watson on 11/23/24.
//

import SwiftUI

struct ConnectForm: View {
    @Environment(IRCClient.self) var client

    @State private var address: String = "localhost"
    @State private var port: String = "6667"
    @State private var password: String = ""

    @AppStorage("nickname") private var nickname = "Beth"
    @AppStorage("username") private var username = "parlor"
    @AppStorage("realname") private var realname = "Parlor User"

    var body: some View {
        Form {
            @Bindable var client = client
            Section {
                TextField("Address", text: $address)
                TextField("Port", text: $port)
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
                client.connect(address, port: UInt16(port)!)
            }
        }
    }
}

#Preview(traits: .modifier(PreviewData())) {
    ConnectForm()
}
