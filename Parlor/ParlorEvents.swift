//
//  ParlorEvents.swift
//  Parlor
//
//  Created by Daniel Watson on 12/3/24.
//

import SwiftUI
import UserNotifications

struct ParlorEvents {
    @AppStorage("playChatSound") private static var playChatSound = true
    @AppStorage("mentionNotifications") private static var mentionNotifications = false

    static func chat(_ message: IRCMessage, mentioned: Bool = false) {
        if playChatSound {
            SoundPlayer.play(.custom("click"))
        }
        if mentioned && mentionNotifications {
            Notifier.notify("notify.mentioned", title: "\(message.user.nickname) mentioned you", body: message.message)
        }
    }
}
