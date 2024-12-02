//
//  SettingsView.swift
//  Parlor
//
//  Created by Daniel Watson on 11/29/24.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("channelLimit") private var channelLimit = 100
    @AppStorage("consoleLimit") private var consoleLimit = 10000
    @AppStorage("showServerInfo") private var showServerInfo = true

    @AppStorage("showTimestamps") private var showTimestamps = true
    @AppStorage("monospace") private var monospace = true
    @AppStorage("showHostmasks") private var showHostmasks = true

    var body: some View {
        TabView {
            Tab("General", systemImage: "gear") {
                Form {
                    TextField("Channel limit", value: $channelLimit, format: .number)
                        #if os(iOS)
                            .overlay(alignment: .trailingFirstTextBaseline) {
                                Text("Channel limit")
                                .foregroundStyle(.secondary)
                            }
                        #endif
                    TextField("Console limit", value: $consoleLimit, format: .number)
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
