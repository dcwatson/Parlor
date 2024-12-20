//
//  ChannelList.swift
//  Parlor
//
//  Created by Daniel Watson on 11/24/24.
//

import SwiftUI

struct ChannelListData: Identifiable, Hashable {
    var name: String
    var count: Int
    var topic: String

    var id: String { name }
}

struct CompactChannelView: View {
    let channel: ChannelListData

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text(channel.name)
                Spacer()
                Text(String(channel.count))
            }
            if !channel.topic.isEmpty {
                Text(channel.topic)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

struct ChannelList: View {
    @Environment(IRCClient.self) var client
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        private var isCompact: Bool { horizontalSizeClass == .compact }
    #else
        private let isCompact = false
    #endif

    @AppStorage("channelLimit") private var channelLimit = 100

    @State private var rawChannels: [String: ChannelListData] = [:]
    @State private var channels: [ChannelListData] = []
    @State private var selectedChannel: ChannelListData.ID? = nil
    @State private var sortOrder = [KeyPathComparator(\ChannelListData.count, order: .reverse)]

    var body: some View {
        Table(channels, selection: $selectedChannel, sortOrder: $sortOrder) {
            TableColumn("Name", value: \.name) { channel in
                if isCompact {
                    CompactChannelView(channel: channel)
                } else {
                    Text(channel.name)
                }
            }
            TableColumn("Users", value: \.count) { channel in
                Text(String(channel.count))
            }
            TableColumn("Topic", value: \.topic)
        }
        .onChange(of: sortOrder) {
            channels.sort(using: sortOrder)
        }
        .contextMenu(forSelectionType: ChannelListData.ID.self) { selection in
            Button("Join") {
                if let channelName = selection.first {
                    client.send(.join(channel: channelName))
                }
            }
        } primaryAction: { selection in
            if let channelName = selection.first {
                client.send(.join(channel: channelName))
            }
        }
        .navigationTitle("Channels")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                refresh()
            }
        #endif
        .task {
            refresh()
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .onReceive(client.events) { event in
            switch event {
            case .channelList(let name, let count, let topic):
                rawChannels[name] = ChannelListData(name: name, count: count, topic: topic)
            case .channelListEnd:
                let sortedChannels = rawChannels.values.sorted(by: { $0.count > $1.count })
                let maxChannels = min(sortedChannels.count, channelLimit)
                channels = Array(sortedChannels[..<maxChannels])
            default:
                break
            }
        }
    }

    func refresh() {
        rawChannels = [:]
        channels = []
        client.send(.custom(command: "LIST"))
    }
}

#Preview(traits: .modifier(PreviewData())) {
    ChannelList()
}
