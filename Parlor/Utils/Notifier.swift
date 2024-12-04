//
//  Notifier.swift
//  Parlor
//
//  Created by Daniel Watson on 12/3/24.
//

import UserNotifications

struct Notifier {
    static private var hasPermission: Bool = false

    static func checkPermission() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            hasPermission = settings.authorizationStatus == .authorized
        }
    }

    static func requestPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            hasPermission = granted
        }
    }

    static func notify(_ id: String, title: String, body: String) {
        if !hasPermission { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
