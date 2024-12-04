//
//  SoundPlayer.swift
//  Parlor
//
//  Created by Daniel Watson on 12/3/24.
//

import AVFoundation

enum Sound {
    case custom(String)
}

struct SoundPlayer {
    static var playerCache: [String: AVAudioPlayer] = [:]

    static func play(_ sound: Sound) {
        switch sound {
        case .custom(let filename):
            if let player = playerCache[filename] {
                player.play()
            } else {
                if let url = Bundle.main.url(forResource: filename, withExtension: "aiff") {
                    if let player = try? AVAudioPlayer(contentsOf: url) {
                        player.prepareToPlay()
                        player.play()
                        playerCache[filename] = player
                    }
                }
            }
        }
    }
}
