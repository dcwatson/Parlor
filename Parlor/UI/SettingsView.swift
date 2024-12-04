//
//  SettingsView.swift
//  Parlor
//
//  Created by Daniel Watson on 11/29/24.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("channelLimit") private var channelLimit = 100
    @AppStorage("messageLimit") private var messageLimit = 1000
    @AppStorage("consoleLimit") private var consoleLimit = 10000
    @AppStorage("showServerInfo") private var showServerInfo = true

    @AppStorage("showTimestamps") private var showTimestamps = true
    @AppStorage("monospace") private var monospace = true
    @AppStorage("showHostmasks") private var showHostmasks = true

    @AppStorage("playChatSound") private var playChatSound = true
    @AppStorage("mentionNotifications") private var mentionNotifications = false

    var body: some View {
        TabView {
            Tab("General", systemImage: "gear") {
                Form {
                    TextField("Channel list limit", value: $channelLimit, format: .number)
                        #if os(iOS)
                            .overlay(alignment: .trailingFirstTextBaseline) {
                                Text("Channel limit")
                                .foregroundStyle(.secondary)
                            }
                        #endif
                    TextField("Message limit", value: $messageLimit, format: .number)
                        #if os(iOS)
                            .overlay(alignment: .trailingFirstTextBaseline) {
                                Text("Message limit")
                                .foregroundStyle(.secondary)
                            }
                        #endif
                    TextField("Console backlog limit", value: $consoleLimit, format: .number)
                        #if os(iOS)
                            .overlay(alignment: .trailingFirstTextBaseline) {
                                Text("Console limit")
                                .foregroundStyle(.secondary)
                            }
                        #endif
                    Toggle("Show server info", isOn: $showServerInfo)
                }
            }

            Tab("Appearance", systemImage: "macwindow") {
                Form {
                    Toggle("Show timestamps", isOn: $showTimestamps)
                    Toggle("Show hostmasks in user lists", isOn: $showHostmasks)
                    Toggle("Use monospace font", isOn: $monospace)
                }
            }
            
            Tab("Notifications", systemImage: "speaker") {
                Form {
                    Toggle("Play chat sound", isOn: $playChatSound)
                    Toggle("Send notifications when mentioned", isOn: $mentionNotifications)
                }
                .onChange(of: mentionNotifications) {
                    if mentionNotifications {
                        Notifier.requestPermission()
                    }
                }
            }
        }
        #if os(macOS)
            .scenePadding()
            .frame(width: 350, height: 150)
        #endif
    }
}

#Preview {
    SettingsView()
}
