//
//  ConversationView.swift
//  Parlor
//
//  Created by Daniel Watson on 11/28/24.
//

import SwiftUI

struct ConversationView: View {
    @Environment(IRCClient.self) var client
    @Environment(IRCConversation.self) var conversation

    @State private var inputText: String = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 5) {
                    ForEach(conversation.messages) { message in
                        MessageView(message: message)
                    }
                }
                .padding()
            }
            .background(.background)
            .defaultScrollAnchor(.bottom)

            TextField("Message \(conversation.user.nickname)", text: $inputText)
                .padding(10)
                .textFieldStyle(.plain)
                .focused($inputFocused)
                .onSubmit {
                    client.send(.privmsg(target: conversation.user.nickname, message: inputText))
                    inputText = ""
                }
        }
        .navigationTitle(conversation.user.nickname)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            inputFocused = true
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    client.removeConversation(conversation)
                    client.appEvent(.popNavigation)
                } label: {
                    Label("Close", systemImage: "slash.circle")
                }
            }
        }
    }
}

#Preview(traits: .modifier(PreviewData())) {
    ConversationView()
}
