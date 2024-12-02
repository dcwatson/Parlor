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

private func getTLSParameters(allowInsecure: Bool, queue: DispatchQueue) -> NWParameters {
    let options = NWProtocolTLS.Options()

    sec_protocol_options_set_verify_block(
        options.securityProtocolOptions,
        { (sec_protocol_metadata, sec_trust, sec_protocol_verify_complete) in

            let trust = sec_trust_copy_ref(sec_trust).takeRetainedValue()

            var error: CFError?
            if SecTrustEvaluateWithError(trust, &error) {
                sec_protocol_verify_complete(true)
            } else {
                if allowInsecure == true {
                    sec_protocol_verify_complete(true)
                } else {
                    sec_protocol_verify_complete(false)
                }
            }

        }, queue)

    return NWParameters(tls: options)
}

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

    func connect(_ host: String, port: UInt16 = 6667, useTLS: Bool = false) {
        if state != .disconnected { return }
        let params = useTLS ? getTLSParameters(allowInsecure: true, queue: .main) : NWParameters(tls: nil, tcp: .init())
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

    func write(_ message: IRCLine, includeTags: Bool = true) {
        guard let data = message.toString(includeTags).data(using: .utf8) else { return }
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
            print("waiting:", error.localizedDescription)
        case .preparing:
            break
        case .ready:
            self.state = .connected
            self.readData()
        case .failed(let error):
            print("connection failed:", error.localizedDescription)
            self.close()
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
