//
//  IRCConnection.swift
//  Parlor
//
//  Created by Daniel Watson on 11/18/24.
//

import Combine
import Foundation
import Network

let crlf: Data = Data([13, 10])

class IRCConnection {
    enum State {
        case disconnected
        case connecting
        case connected
        case ready
    }

    private var conn: NWConnection? = nil
    private var buffer: Data = .init()
    private var lineStream = PassthroughSubject<IRCLine, Never>()

    @Published var state: State = .disconnected
    lazy var lines = lineStream.eraseToAnyPublisher()

    func connect(_ host: String, port: UInt16 = 6667) {
        if state != .disconnected { return }
        let params = NWParameters(tls: nil, tcp: .init())
        conn = NWConnection(host: .init(host), port: .init(integerLiteral: port), using: params)
        conn?.stateUpdateHandler = self.handleStateChange(to:)
        conn?.start(queue: .main)
        state = .connecting
    }

    func close() {
        if let conn {
            conn.stateUpdateHandler = nil
            conn.cancel()
        }
        conn = nil
        state = .disconnected
    }

    func write(_ message: IRCLine) {
        guard let data = message.stringValue.data(using: .utf8) else { return }
        conn?.send(
            content: data + crlf,
            completion: .contentProcessed { err in
                if let err {
                    print(err.localizedDescription)
                }
            })
    }

    private func handleStateChange(to state: NWConnection.State) {
        switch state {
        case .setup:
            break
        case .waiting(let error):
            print(error.localizedDescription)
        case .preparing:
            break
        case .ready:
            self.state = .connected
            self.readData()
        case .failed(let error):
            print(error.localizedDescription)
        case .cancelled:
            print("cancelled")
        default:
            break
        }
    }

    private func parseMessages(_ data: Data) {
        buffer.append(data)
        var current = buffer.startIndex
        for sep in buffer.ranges(of: crlf) {
            if let line = String(data: buffer[current..<sep.lowerBound], encoding: .utf8) {
                lineStream.send(.parse(line))
            }
            current = sep.upperBound
        }
        buffer.removeFirst(buffer.distance(from: buffer.startIndex, to: current))
    }

    private func readData() {
        conn?.receive(minimumIncompleteLength: 1, maximumLength: 65536) {
            [weak self] data, context, complete, error in

            guard let self else { return }

            if let error {
                print("IRCConnection.readData:", error.localizedDescription)
                // read again? close?
            } else if let data {
                self.parseMessages(data)
                self.readData()
            } else {
                self.close()
            }
        }
    }
}
