//
//  ConversationView.swift
//  Parlor
//
//  Created by Daniel Watson on 11/28/24.
//

import SwiftUI

struct ConversationView: View {
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        private var isCompact: Bool { horizontalSizeClass == .compact }
    #else
        private let isCompact = false
    #endif

    @Environment(IRCClient.self) var client
    @Environment(IRCConversation.self) var conversation

    @State private var inputText: String = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: isCompact ? 15 : 5) {
                ForEach(conversation.messages) { message in
                    MessageView(message: message)
                }
            }
            .padding()
        }
        .background(.background)
        .defaultScrollAnchor(.bottom)
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: 80)
        }
        .overlay(alignment: .bottom) {
            InputView(
                placeholder: "Message \(conversation.user.nickname)",
                text: $inputText,
                focused: $inputFocused
            ) {
                text in
                client.send(.privmsg(target: conversation.user.nickname, message: text))
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
            ToolbarSpacer(.flexible)

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
        .environment(IRCConversation(user: .init("SomeGuy!user@host.com")))
}
