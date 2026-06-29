//
//  Protected.swift
//  Kingfisher
//
//  Created by Kingfisher contributors on 2026/06/29.
//
//  Copyright (c) 2026 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

/// A lock-guarded wrapper that provides thread-safe access to a value.
///
/// Many of Kingfisher's `@unchecked Sendable` types guard mutable state with the
/// "private `_value` + a computed accessor that locks each get and set" idiom. That makes each
/// *individual* read or write atomic, but it does **not** make a *compound* read-modify-write atomic:
/// `let v = value; value = f(v)` performs two separate critical sections with a gap in between, which
/// races under concurrency.
///
/// `Protected` closes that gap by exposing ``withLock(_:)``, so a whole read-modify-write runs as one
/// critical section. Prefer it over a bare lock + property whenever more than a single get or set has to
/// happen atomically.
final class Protected<Value>: @unchecked Sendable {

    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    /// Runs `body` with exclusive, mutable access to the wrapped value and returns its result.
    ///
    /// Use this for compound operations that must be atomic as a whole, e.g. "look up, and if absent
    /// insert". The lock is held for the duration of `body`, so keep it short and do not call back into
    /// the same `Protected` from within `body` (the lock is not recursive).
    @discardableResult
    func withLock<Result>(_ body: (inout Value) throws -> Result) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try body(&value)
    }

    /// An atomically-read snapshot of the current value.
    var current: Value {
        withLock { $0 }
    }
}
