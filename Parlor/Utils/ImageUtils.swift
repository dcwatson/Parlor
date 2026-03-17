//
//  ImageUtils.swift
//  Parlor
//
//  Created by Daniel Watson on 3/15/26.
//

import Foundation

func fetchContentType(_ url: URL, timeout: TimeInterval = 5) async -> String? {
    var request = URLRequest(url: url)
    request.httpMethod = "HEAD"
    request.timeoutInterval = timeout

    do {
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            return nil
        }

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            return nil
        }

        return httpResponse.value(forHTTPHeaderField: "Content-Type")?
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
        return nil
    }
}
