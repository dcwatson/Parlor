//
//  Parlor.swift
//  Parlor
//
//  Created by Daniel Watson on 4/1/26.
//

import Observation
import SwiftData

@MainActor
@Observable
final class Parlor {
    var container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Server.self)
            //container.deleteAllData()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    /*
    func initialize() {
        let descriptor = FetchDescriptor<Server>()
        if let servers = try? container.mainContext.fetch(descriptor) {
            for server in servers {
                clients.append(IRCClient(server))
            }
        }
        if let client = clients.first {
            activeClient = client
        }
    }
     */
}
