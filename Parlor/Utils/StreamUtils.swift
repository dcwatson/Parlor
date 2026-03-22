//
//  StreamUtils.swift
//  Parlor
//
//  Created by Daniel Watson on 3/19/26.
//

import SwiftUI
import Synchronization
import _Concurrency

public final class Streamer<Value: Sendable>: Sendable {
    private let subscriptions = Mutex<[UUID: AsyncStream<Value>.Continuation]>([:])

    var stream: AsyncStream<Value> {
        let id = UUID()
        return AsyncStream { continuation in
            subscriptions.withLock {
                $0[id] = continuation
            }
            continuation.onTermination = { _ in
                self.subscriptions.withLock {
                    let _ = $0.removeValue(forKey: id)
                }
            }
        }
    }

    func broadcast(_ message: Value) {
        subscriptions.withLock {
            for continuation in $0.values {
                continuation.yield(message)
            }
        }
    }
}

struct _StreamModifier<T: Sendable>: ViewModifier {
    let iter: AsyncStream<T>
    let action: @Sendable (T) async -> Void

    func body(content: Content) -> some View {
        content.task {
            for await value in iter {
                await action(value)
            }
        }
    }
}

extension View {
    public func stream<T: Sendable>(
        _ iter: AsyncStream<T>,
        @_inheritActorContext action: @escaping @Sendable (T) async -> Void
    ) -> some View {
        modifier(_StreamModifier(iter: iter, action: action))
    }

    public func stream<Value: Sendable>(
        _ iter: Streamer<Value>,
        @_inheritActorContext action: @escaping @Sendable (Value) async -> Void
    ) -> some View {
        modifier(_StreamModifier(iter: iter.stream, action: action))
    }
}
