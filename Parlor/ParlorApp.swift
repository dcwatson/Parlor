//
//  ParlorApp.swift
//  Parlor
//
//  Created by Daniel Watson on 11/15/24.
//

import SwiftUI

@main
struct ParlorApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                Notifier.checkPermission()
            }
        }

        #if os(macOS)
            Settings {
                SettingsView()
            }
        #endif
    }
}
