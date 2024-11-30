//
//  ParlorApp.swift
//  Parlor
//
//  Created by Daniel Watson on 11/15/24.
//

import SwiftUI

@main
struct ParlorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        #if os(macOS)
            Settings {
                SettingsView()
            }
        #endif
    }
}
