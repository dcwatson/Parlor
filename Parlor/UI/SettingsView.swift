//
//  SettingsView.swift
//  Parlor
//
//  Created by Daniel Watson on 11/29/24.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("channelLimit") private var channelLimit = 100
    @AppStorage("showServerInfo") private var showServerInfo = true

    @AppStorage("showTimestamps") private var showTimestamps = true

    var body: some View {
        TabView {
            Tab("General", systemImage: "gear") {
                Form {
                    TextField("Channel limit", value: $channelLimit, format: .number)
                    Toggle("Show server info", isOn: $showServerInfo)
                }
            }

            Tab("Appearance", systemImage: "macwindow") {
                Form {
                    Toggle("Show timestamps", isOn: $showTimestamps)
                }
            }
        }
        .scenePadding()
        .frame(width: 350, height: 150)
    }
}

#Preview {
    SettingsView()
}
