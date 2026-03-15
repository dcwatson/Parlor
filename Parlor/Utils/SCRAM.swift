//
//  SCRAM.swift
//  Parlor
//
//  Created by Daniel Watson on 3/14/26.
//

import CommonCrypto
import Foundation
import Security

final class SCRAM {
    enum Algorithm: String {
        case sha1 = "SCRAM-SHA-1"
        case sha256 = "SCRAM-SHA-256"

        var hmacAlgorithm: CCHmacAlgorithm {
            switch self {
            case .sha1:
                CCHmacAlgorithm(kCCHmacAlgSHA1)
            case .sha256:
                CCHmacAlgorithm(kCCHmacAlgSHA256)
            }
        }

        var pbkdfAlgorithm: CCPseudoRandomAlgorithm {
            switch self {
            case .sha1:
                CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1)
            case .sha256:
                CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256)
            }
        }

        var digestLength: Int {
            switch self {
            case .sha1:
                Int(CC_SHA1_DIGEST_LENGTH)
            case .sha256:
                Int(CC_SHA256_DIGEST_LENGTH)
            }
        }
    }

    struct ServerFirstMessage {
        let nonce: String
        let salt: Data
        let iterations: Int
        let extensions: [String: String]
    }

    struct ServerFinalMessage {
        let verifier: Data?
        let error: String?
        let extensions: [String: String]
    }

    enum Error: Swift.Error, LocalizedError {
        case invalidMessage
        case missingAttribute(String)
        case invalidNonce
        case invalidSalt
        case invalidIterationCount
        case invalidVerifier
        case serverError(String)
        case protocolOutOfSequence
        case signatureMismatch
        case randomGenerationFailed
        case keyDerivationFailed

        var errorDescription: String? {
            switch self {
            case .invalidMessage:
                "Invalid SCRAM message"
            case .missingAttribute(let attribute):
                "Missing SCRAM attribute: \(attribute)"
            case .invalidNonce:
                "Invalid SCRAM nonce"
            case .invalidSalt:
                "Invalid SCRAM salt"
            case .invalidIterationCount:
                "Invalid SCRAM iteration count"
            case .invalidVerifier:
                "Invalid SCRAM verifier"
            case .serverError(let message):
                "SCRAM server error: \(message)"
            case .protocolOutOfSequence:
                "SCRAM methods were called out of sequence"
            case .signatureMismatch:
                "SCRAM server signature did not match"
            case .randomGenerationFailed:
                "Unable to generate a SCRAM nonce"
            case .keyDerivationFailed:
                "Unable to derive SCRAM credentials"
            }
        }
    }

    enum Status {
        case notStarted
        case awaitingServerFirst
        case awaitingServerFinal
        case complete
    }

    let username: String
    let password: String
    let algorithm: Algorithm

    var status: Status = .notStarted

    private let gs2Header: String = "n,,"

    private var clientNonce: String?
    private var clientFirstBare: String?
    private var serverFirstRaw: String?
    private var serverFirstMessage: ServerFirstMessage?
    private var expectedServerSignature: Data?

    init(username: String, password: String, algorithm: Algorithm) {
        self.username = username
        self.password = password
        self.algorithm = algorithm
    }

    func generateClientFirstMessage() throws -> String {
        let nonce = try Self.makeNonce()
        let bare = "n=\(Self.escapeName(username)),r=\(nonce)"

        clientNonce = nonce
        clientFirstBare = bare
        serverFirstRaw = nil
        serverFirstMessage = nil
        expectedServerSignature = nil

        status = .awaitingServerFirst

        return gs2Header + bare
    }

    @discardableResult
    func parseServerFirstMessage(_ message: String) throws -> ServerFirstMessage {
        guard let clientNonce, clientFirstBare != nil else {
            throw Error.protocolOutOfSequence
        }

        let attributes = try Self.parseAttributes(message)
        guard let nonce = attributes["r"] else {
            throw Error.missingAttribute("r")
        }
        guard nonce.hasPrefix(clientNonce) else {
            throw Error.invalidNonce
        }
        guard let saltValue = attributes["s"], let salt = Data(base64Encoded: saltValue) else {
            throw Error.invalidSalt
        }
        guard let iterationValue = attributes["i"], let iterations = Int(iterationValue),
            iterations > 0
        else {
            throw Error.invalidIterationCount
        }

        var extensions = attributes
        extensions.removeValue(forKey: "r")
        extensions.removeValue(forKey: "s")
        extensions.removeValue(forKey: "i")

        serverFirstRaw = message
        let parsed = ServerFirstMessage(
            nonce: nonce,
            salt: salt,
            iterations: iterations,
            extensions: extensions
        )
        serverFirstMessage = parsed

        return parsed
    }

    func generateClientFinalMessage() throws -> String {
        guard
            let clientFirstBare,
            let serverFirstRaw,
            let clientNonce,
            let serverFirstMessage
        else {
            throw Error.protocolOutOfSequence
        }

        guard serverFirstMessage.nonce.hasPrefix(clientNonce) else {
            throw Error.invalidNonce
        }

        let finalWithoutProof =
            "c=\(Data(gs2Header.utf8).base64EncodedString()),r=\(serverFirstMessage.nonce)"
        let authMessage = "\(clientFirstBare),\(serverFirstRaw),\(finalWithoutProof)"

        let saltedPassword = try deriveSaltedPassword(
            salt: serverFirstMessage.salt,
            iterations: serverFirstMessage.iterations
        )
        let clientKey = hmac(key: saltedPassword, string: "Client Key")
        let storedKey = hash(clientKey)
        let clientSignature = hmac(key: storedKey, string: authMessage)
        let clientProof = Data(clientKey.xor(clientSignature)).base64EncodedString()
        let serverKey = hmac(key: saltedPassword, string: "Server Key")
        let serverSignature = hmac(key: serverKey, string: authMessage)

        expectedServerSignature = serverSignature
        status = .awaitingServerFinal

        return "\(finalWithoutProof),p=\(clientProof)"
    }

    @discardableResult
    func parseServerFinalMessage(_ message: String) throws -> ServerFinalMessage {
        guard expectedServerSignature != nil else {
            throw Error.protocolOutOfSequence
        }

        let attributes = try Self.parseAttributes(message)
        if let error = attributes["e"] {
            throw Error.serverError(error)
        }

        guard let verifierValue = attributes["v"] else {
            throw Error.missingAttribute("v")
        }
        guard let verifier = Data(base64Encoded: verifierValue) else {
            throw Error.invalidVerifier
        }
        guard verifier == expectedServerSignature else {
            throw Error.signatureMismatch
        }

        var extensions = attributes
        extensions.removeValue(forKey: "v")

        status = .complete

        return ServerFinalMessage(
            verifier: verifier,
            error: nil,
            extensions: extensions
        )
    }

    private func deriveSaltedPassword(salt: Data, iterations: Int) throws -> Data {
        let passwordData = Data(password.utf8)
        var derivedKey = [UInt8](repeating: 0, count: algorithm.digestLength)

        let status = passwordData.withUnsafeBytes { passwordBytes in
            salt.withUnsafeBytes { saltBytes in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    passwordBytes.bindMemory(to: Int8.self).baseAddress,
                    passwordData.count,
                    saltBytes.bindMemory(to: UInt8.self).baseAddress,
                    salt.count,
                    algorithm.pbkdfAlgorithm,
                    UInt32(iterations),
                    &derivedKey,
                    derivedKey.count
                )
            }
        }

        guard status == kCCSuccess else {
            throw Error.keyDerivationFailed
        }

        return Data(derivedKey)
    }

    private func hmac(key: Data, string: String) -> Data {
        hmac(key: key, data: Data(string.utf8))
    }

    private func hmac(key: Data, data: Data) -> Data {
        var result = [UInt8](repeating: 0, count: algorithm.digestLength)

        key.withUnsafeBytes { keyBytes in
            data.withUnsafeBytes { dataBytes in
                CCHmac(
                    algorithm.hmacAlgorithm,
                    keyBytes.baseAddress,
                    key.count,
                    dataBytes.baseAddress,
                    data.count,
                    &result
                )
            }
        }

        return Data(result)
    }

    private func hash(_ data: Data) -> Data {
        var result = [UInt8](repeating: 0, count: algorithm.digestLength)

        data.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }

            switch algorithm {
            case .sha1:
                CC_SHA1(baseAddress, CC_LONG(data.count), &result)
            case .sha256:
                CC_SHA256(baseAddress, CC_LONG(data.count), &result)
            }
        }

        return Data(result)
    }

    private static func escapeName(_ value: String) -> String {
        value
            .replacingOccurrences(of: "=", with: "=3D")
            .replacingOccurrences(of: ",", with: "=2C")
    }

    private static func makeNonce(length: Int = 18) throws -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        guard status == errSecSuccess else {
            throw Error.randomGenerationFailed
        }

        return Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: ",", with: "")
    }

    private static func parseAttributes(_ message: String) throws -> [String: String] {
        guard !message.isEmpty else {
            throw Error.invalidMessage
        }

        var attributes: [String: String] = [:]

        for component in message.split(separator: ",", omittingEmptySubsequences: false) {
            guard let equalsIndex = component.firstIndex(of: "="),
                equalsIndex != component.startIndex
            else {
                throw Error.invalidMessage
            }

            let key = String(component[..<equalsIndex])
            let value = String(component[component.index(after: equalsIndex)...])
            guard !key.isEmpty else {
                throw Error.invalidMessage
            }
            attributes[key] = value
        }

        return attributes
    }
}

extension Data {
    fileprivate func xor(_ other: Data) -> [UInt8] {
        zip(self, other).map(^)
    }
}
