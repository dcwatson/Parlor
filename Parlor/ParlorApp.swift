//
//  ParlorApp.swift
//  Parlor
//
//  Created by Daniel Watson on 11/15/24.
//

import SwiftData
import SwiftUI
import os

let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "General")

struct ChannelCommands: Commands {
    @FocusedValue(IRCClient.self) private var client: IRCClient?
    @FocusedValue(IRCChannel.self) private var channel: IRCChannel?

    var body: some Commands {
        CommandMenu("Channel") {
            Button("Join…") {
                client?.appEvent(.joinCommand)
            }
            .keyboardShortcut("j")
            .disabled(client == nil)

            Button("Part") {
                if let channel {
                    client?.appEvent(.partCommand(channel))
                }
            }
            .keyboardShortcut("p")
            .disabled(client == nil || channel == nil)

            Button("Set Topic…") {
                if let channel {
                    client?.appEvent(.setTopicCommand(channel))
                }
            }
            .keyboardShortcut("t")
            .disabled(client == nil || channel == nil)

            Divider()

            Button("Toggle Inspector") {}
                .keyboardShortcut("i")
                .disabled(client == nil)

            Button("Show Users") {}
                .keyboardShortcut("u")
                .disabled(client == nil)

            Button("Show Links") {}
                .keyboardShortcut("l")
                .disabled(client == nil)

            if let channels = client?.channels, !channels.isEmpty {
                Divider()

                ForEach(channels.enumerated(), id: \.offset) { index, channel in
                    Button(channel.name) {
                        client?.appEvent(.jumpToChannel(channel))
                    }
                    .keyboardShortcut(.init(Character(String(index + 1))))
                    .disabled(client == nil)
                }
            }
        }
    }
}

#if os(macOS)
    class AppDelegate: NSObject, NSApplicationDelegate {
        func applicationDidFinishLaunching(_ notification: Notification) {
            print("APP LAUNCHED")
        }

        func application(
            _ application: NSApplication,
            didReceiveRemoteNotification userInfo: [String: Any]
        ) {
            print("Notification received: \(userInfo)")
        }
    }
#else
    class AppDelegate: NSObject, UIApplicationDelegate {
        func application(
            _ application: UIApplication,
            didReceiveRemoteNotification userInfo: [AnyHashable: Any],
            fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
        ) {
            print("Notification received: \(userInfo)")
            completionHandler(.noData)
        }
    }
#endif

@main
struct ParlorApp: App {
    #if os(macOS)
        @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #else
        @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    @Environment(\.scenePhase) private var scenePhase

    @State private var parlor = Parlor()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(parlor)
        }
        //.windowToolbarStyle(.unified(showsTitle: true))
        .modelContainer(parlor.container)
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                Notifier.checkPermission()
            }
        }
        .commands {
            ChannelCommands()
        }

        #if os(macOS)
            Settings {
                SettingsView()
            }
        #endif
    }
}
