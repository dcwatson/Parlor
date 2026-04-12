//
//  ChannelView.swift
//  Parlor
//
//  Created by Daniel Watson on 11/19/24.
//

import SwiftUI

struct ChannelView: View {
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        private var isCompact: Bool { horizontalSizeClass == .compact }
    #else
        private let isCompact = false
    #endif

    @Environment(IRCClient.self) var client
    @Environment(IRCChannel.self) var channel

    @AppStorage("monospace") private var monospace = false

    @State private var inputText: String = ""
    @State private var showingTopicAlert: Bool = false
    @State private var newTopic: String = ""
    @State private var position: ScrollPosition = .init(idType: IRCMessage.ID.self)
    @State private var isNearBottom: Bool = true

    @FocusState private var inputFocused: Bool

    #if os(macOS)
        @State private var showingUsers: Bool = true
    #else
        @State private var showingUsers: Bool = false
    #endif

    func part() {
        client.send(.part(channel: channel.name))
        client.appEvent(.popNavigation)
    }

    func handleAppEvent(_ event: AppEvent) {
        switch event {
        case .partCommand(let c):
            if c == channel { part() }
        case .setTopicCommand(let c):
            if c == channel { showingTopicAlert = true }
        default:
            break
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 3) {
                ForEach(channel.messages) { message in
                    MessageView(message: message)
                }
            }
            .padding()
            .scrollTargetLayout()
        }
        .focusedSceneValue(channel)
        .onChange(of: channel) { oldChannel, newChannel in
            //position.scrollTo(edge: .bottom)
        }
        .background(.background)
        .defaultScrollAnchor(.bottom)
        .scrollPosition($position, anchor: .bottom)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            let contentBottom =
                geometry.contentOffset.y
                + geometry.containerSize.height
                + geometry.contentInsets.bottom

            return geometry.contentSize.height - contentBottom
        } action: { oldValue, newValue in
            isNearBottom = newValue < 70.0
        }
        .safeAreaPadding(.bottom, 70)
        .onChange(of: channel.messages.last) {
            if isNearBottom {
                position.scrollTo(edge: .bottom)
            }
        }
        .overlay(alignment: .bottom) {
            InputView(
                placeholder: "Message \(channel.name)",
                text: $inputText,
                focused: $inputFocused
            ) { text in
                client.send(.privmsg(target: channel.name, message: text))
                inputText = ""
            }
        }
        .navigationTitle(channel.name)
        .navigationSubtitle(channel.topic)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .task(id: channel.id) {
            inputFocused = true

            for await event in client.events.stream {
                if case .app(let ae) = event {
                    handleAppEvent(ae)
                }
            }
        }
        .inspector(isPresented: $showingUsers) {
            UserList()
                #if os(macOS)
                    .inspectorColumnWidth(min: 200, ideal: 250, max: 400)
                #endif
        }
        .toolbar {
            ToolbarSpacer(.flexible)

            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showingTopicAlert = true
                } label: {
                    Label("Set Topic", systemImage: "text.bubble")
                }
                .alert("Set Topic", isPresented: $showingTopicAlert) {
                    TextField("New topic for \(channel.name)", text: $newTopic)
                    Button("OK") {
                        client.send(.topic(channel: channel.name, topic: newTopic))
                        newTopic = ""
                    }
                }

                Button {
                    part()
                } label: {
                    Label("Leave", systemImage: "slash.circle")
                }

                Button {
                    showingUsers.toggle()
                } label: {
                    Label("Toggle Users", systemImage: "person")
                }
            }
        }
    }
}

#Preview(traits: .modifier(PreviewData())) {
    ChannelView()
}
