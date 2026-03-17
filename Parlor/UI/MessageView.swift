//
//  MessageView.swift
//  Parlor
//
//  Created by Daniel Watson on 11/29/24.
//

import QuickLook
import SwiftUI

struct DateDivider: View {
    let date: Date

    var body: some View {
        HStack {
            Spacer()
            Text(dateFormatter.string(from: date))
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
            Spacer()
        }
        .textSelection(.enabled)
        .padding(.vertical, 12)
    }
}

struct MessageImages: View {
    let message: IRCMessage

    @State private var showUrl: URL? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top) {
                ForEach(message.imageUrls, id: \.absoluteString) { url in
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFit()
                        }
                    }
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .pointerStyle(.link)
                    .onTapGesture {
                        showUrl = url
                    }
                }
            }
            .quickLookPreview($showUrl)
        }
    }
}

struct MessageText: View {
    @AppStorage("showInlineImages") private var showInlineImages = true

    let message: IRCMessage

    var attributedString: AttributedString {
        do {
            return try AttributedString(markdown: message.message)
        } catch {
            return AttributedString(message.message)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(attributedString)

            if showInlineImages && message.imageUrls.count > 0 {
                MessageImages(message: message)
            }
        }
        .task {
            await message.detectUrls()
        }
    }
}

struct FullMessageView: View {
    @AppStorage("showTimestamps") private var showTimestamps = true
    @AppStorage("monospace") private var monospace = false

    let message: IRCMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if message.dateChanged {
                DateDivider(date: message.timestamp)
            }
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                if showTimestamps {
                    Text(message.maybeTimeString)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .frame(width: 60, alignment: .trailing)
                }
                Text(message.nickname)
                    .bold()
                    .foregroundStyle(Color.accentColor)
                MessageText(message: message)
            }
            .textSelection(.enabled)
        }
        .monospaced(monospace)
    }
}

struct CompactMessageView: View {
    @AppStorage("showTimestamps") private var showTimestamps = true
    @AppStorage("monospace") private var monospace = false

    let message: IRCMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if message.nickChanged || (showTimestamps && message.timeChanged) {
                Spacer().frame(height: 5)

                HStack(alignment: .firstTextBaseline) {
                    Text(message.nickname)
                        .bold()
                        .foregroundStyle(Color.accentColor)
                    //.padding(.top, 5)
                    if showTimestamps && message.timeChanged {
                        Text(timeFormatter.string(from: message.timestamp))
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                }
            }

            MessageText(message: message)
        }
        .monospaced(monospace)
        .textSelection(.enabled)
    }
}

struct MessageView: View {
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        private var isCompact: Bool { horizontalSizeClass == .compact }
    #else
        private let isCompact = false
    #endif

    let message: IRCMessage

    var body: some View {
        if isCompact {
            CompactMessageView(message: message)
        } else {
            FullMessageView(message: message)
        }
    }
}

#Preview("Full Size", traits: .modifier(PreviewData())) {
    @Previewable @Environment(IRCClient.self) var client

    VStack(alignment: .leading, spacing: 3) {
        ForEach(client.channels[0].messages) { msg in
            FullMessageView(message: msg)
        }
    }
    .frame(height: 200)
    .padding()
}

#Preview("Compact", traits: .modifier(PreviewData())) {
    @Previewable @Environment(IRCClient.self) var client

    VStack(alignment: .leading, spacing: 3) {
        ForEach(client.channels[0].messages) { msg in
            CompactMessageView(message: msg)
        }
    }
    .frame(height: 250)
    .padding()
}
