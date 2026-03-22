//
//  IRCConnection.swift
//  Parlor
//
//  Created by Daniel Watson on 11/18/24.
//

import Foundation
import Network
import Synchronization

let crlf: Data = Data([13, 10])

final class IRCConnection: @unchecked Sendable {
    enum Event {
        case connected
        case disconnected
        case lineReceived(IRCLine)
    }

    struct LineParser {
        var buffer = Data()

        mutating func parseLines(_ data: Data) -> [IRCLine] {
            var lines: [IRCLine] = []
            buffer.append(data)
            var current = buffer.startIndex
            for sep in buffer.ranges(of: crlf) {
                if let line = String(data: buffer[current..<sep.lowerBound], encoding: .utf8) {
                    lines.append(IRCLine.parse(line))
                }
                current = sep.upperBound
            }
            buffer.removeFirst(buffer.distance(from: buffer.startIndex, to: current))
            return lines
        }
    }

    let events = Streamer<Event>()

    private var conn: NetworkConnection<TCP>?
    private var clientLoop: Task<Void, Never>?

    func connect(_ host: String, port: UInt16 = 6667, useTLS: Bool = false) {
        guard conn == nil else { return }

        let conn = NetworkConnection(
            to: .hostPort(host: .init(host), port: .init(integerLiteral: port)),
            using: .parameters {
                TCP {
                    IP()
                }
            }
        )
        self.conn = conn

        conn.onStateUpdate { c, state in
            if state == .ready {
                self.events.broadcast(.connected)
            }
        }

        clientLoop = Task {
            var parser = LineParser()
            while !Task.isCancelled {
                do {
                    let (data, _) = try await conn.receive(atLeast: 1, atMost: 65536)
                    for line in parser.parseLines(data) {
                        events.broadcast(.lineReceived(line))
                    }
                } catch {
                    print(error)
                }
            }
        }
    }

    func close() {
        conn = nil
        clientLoop?.cancel()
        clientLoop = nil
    }

    func write(_ message: IRCLine, includeTags: Bool = true) async throws {
        guard let conn, let data = message.toString(includeTags).data(using: .utf8) else { return }
        try await conn.send(data + crlf)
    }
}
