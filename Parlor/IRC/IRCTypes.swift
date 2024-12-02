//
//  IRCTypes.swift
//  Parlor
//
//  Created by Daniel Watson on 11/18/24.
//

import Foundation

struct IRCCapability: Identifiable {
    var name: String
    var value: String? = nil
    var vendor: String? = nil
    var negate: Bool = false

    var id: String {
        guard let vendor else { return name }
        return "\(vendor)/\(name)"
    }

    var stringValue: String {
        var cap = ""
        if let vendor {
            cap += vendor + "/"
        }
        cap += name
        if let value {
            cap += "=" + value
        }
        return cap
    }

    init(_ cap: String) {
        let reader = StringReader(cap)

        negate = reader.peek() == "-"
        if negate { reader.skip(1) }

        let nameParts = reader.readUntil("=").split(separator: "/", maxSplits: 1)
        vendor = nameParts.count > 1 ? String(nameParts[0]) : nil
        name = String(nameParts.last!)

        value = reader.remaining() > 0 ? reader.read() : nil
    }
}

typealias IRCCapabilities = [IRCCapability]

extension IRCCapabilities {
    init(_ capData: String) {
        self.init()
        for cap in capData.split(separator: " ") {
            self.append(.init(String(cap)))
        }
    }

    func get(_ name: String, vendor: String? = nil) -> IRCCapability? {
        for cap in self {
            if cap.name != name { continue }
            if let vendor, cap.vendor != vendor { continue }
            return cap
        }
        return nil
    }

    func has(_ name: String, vendor: String? = nil) -> Bool {
        get(name, vendor: vendor) != nil
    }

    mutating func ack(_ other: IRCCapabilities) {
        for cap in other {
            if cap.negate { continue }
            if has(cap.name, vendor: cap.vendor) { continue }
            self.append(cap)
        }
    }

    func intersection(_ other: IRCCapabilities) -> IRCCapabilities {
        var result: IRCCapabilities = []
        for cap in self {
            if other.has(cap.name, vendor: cap.vendor) {
                result.append(cap)
            }
        }
        return result
    }

    var stringValue: String {
        self.map({ $0.stringValue }).joined(separator: " ")
    }
}

struct IRCTag {
    var client: Bool
    var vendor: String?
    var key: String
    var value: String

    var stringValue: String {
        var t = ""
        if client {
            t += "+"
        }
        if let vendor {
            t += vendor + "/"
        }
        t += key + "=" + value
        return t
    }
}

typealias IRCTags = [IRCTag]

extension IRCTags {
    init(_ tagData: String) {
        self.init()
        for tagString in tagData.split(separator: ";") {
            let client = tagString.hasPrefix("+")
            let tag = tagString.trimmingPrefix("+")
            let tagParts = tag.split(separator: "=", maxSplits: 1)
            // TODO: make sure parts.count == 2
            let keyParts = tagParts.first!.split(separator: "/", maxSplits: 1)
            let vendor = keyParts.count > 1 ? String(keyParts[0]) : nil
            let keyName = String(keyParts.last!)
            let value = String(tagParts.last!)
            self.append(.init(client: client, vendor: vendor, key: keyName, value: value))
        }
    }

    func get(_ name: String, vendor: String? = nil, client: Bool? = nil) -> IRCTag? {
        for tag in self {
            if tag.key != name { continue }
            if let vendor, tag.vendor != vendor { continue }
            if let client, tag.client != client { continue }
            return tag
        }
        return nil
    }

    subscript(_ name: String) -> String? {
        guard let tag = get(name) else { return nil }
        return tag.value
    }
}

class IRCLine: Identifiable {
    var tags: IRCTags
    var source: String?
    var command: String
    var params: [String]
    var outgoing: Bool

    var message: String? { params.last }

    var reply: IRCReply? {
        guard let number = Int(command) else { return nil }
        return IRCReply(rawValue: number)
    }

    var error: IRCError? {
        guard let number = Int(command) else { return nil }
        return IRCError(rawValue: number)
    }

    private init(line: String) {
        let reader = StringReader(line)

        if reader.peek() == "@" {
            reader.skip(1)
            tags = .init(reader.readUntil(" "))
        } else {
            tags = []
        }

        if reader.peek() == ":" {
            reader.skip(1)
            source = reader.readUntil(" ")
        } else {
            source = nil
        }

        command = reader.readUntil(" ", consume: false)
        params = reader.readUntil(" :", consume: false)
            .split(separator: " ", omittingEmptySubsequences: true)
            .map(String.init)

        if reader.peek(2) == " :" {
            reader.skip(2)
            params.append(reader.read())
        }

        outgoing = false
    }

    init(
        _ command: String,
        params: [String] = [],
        tags: IRCTags = [],
        source: String? = nil,
        outgoing: Bool = true
    ) {
        self.tags = tags
        self.source = source
        self.command = command
        self.params = params
        self.outgoing = outgoing
    }

    subscript(_ idx: Int) -> String? {
        self.params.indices.contains(idx) ? self.params[idx] : nil
    }

    subscript(_ name: String) -> String? {
        self.tags[name]
    }

    static func parse(_ line: String) -> IRCLine { return .init(line: line) }
    
    func toString(_ withTags: Bool = true) -> String {
        var line = ""

        if !tags.isEmpty && withTags {
            let t = tags.map { $0.stringValue }.joined(separator: ";")
            line += "@\(t) "
        }

        if let source {
            line += ":\(source) "
        }

        line += command.uppercased()

        for (idx, p) in params.enumerated() {
            if idx == params.count - 1, p.firstIndex(of: " ") != nil {
                line += " :" + p
            } else {
                line += " " + p
            }
        }

        return line
    }

}
