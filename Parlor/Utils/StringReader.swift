//
//  StringReader.swift
//  Parlor
//
//  Created by Daniel Watson on 11/18/24.
//

class StringReader<S: StringProtocol> {
    var string: S
    var position: S.Index

    init(_ string: S) {
        self.string = string
        self.position = string.startIndex
    }

    func peek(_ count: Int = 1) -> String {
        guard
            let end = string.index(
                position, offsetBy: count, limitedBy: string.endIndex)
        else { return "" }
        return String(string[position..<end])
    }

    func skip(_ count: Int) {
        position =
            string
            .index(position, offsetBy: count, limitedBy: string.endIndex) ?? string.endIndex
    }

    func read() -> String {
        defer { position = string.endIndex }
        return String(string[position..<string.endIndex])
    }

    func remaining() -> Int {
        return string.distance(from: position, to: string.endIndex)
    }

    func readUntil(_ sep: String, consume: Bool = true) -> String {
        if let sepRange = string.range(of: sep, range: position..<string.endIndex) {
            defer { position = consume ? sepRange.upperBound : sepRange.lowerBound }
            return String(string[position..<sepRange.lowerBound])
        } else {
            defer { position = string.endIndex }
            return String(string[position..<string.endIndex])
        }
    }
}
