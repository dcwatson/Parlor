//
//  ParlorTests.swift
//  ParlorTests
//
//  Created by Daniel Watson on 11/15/24.
//

import Testing

struct ParlorTests {

    @Test func testSingleMessageParam() async throws {
        let line = IRCLine.parse("NICK :something")
        #expect(line.command == "NICK")
        #expect(line.params == ["something"])
    }

    @Test func testColonsInParams() async throws {
        let line = IRCLine.parse(":server 005 KEY=1:2:3 FLAG NAME=4:5:6 :something else")
        #expect(line.command == "005")
        #expect(line.source == "server")
        #expect(line.params == ["KEY=1:2:3", "FLAG", "NAME=4:5:6", "something else"])
    }
}
