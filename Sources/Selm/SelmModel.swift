//
// Created by 和泉田 領一 on 2019/12/20.
//

import Foundation

public protocol SelmModel {
    static func equals(_ lhs: Self, _ rhs: Self) -> Bool
}

extension SelmModel {
    public static func equals(_ lhs: Self, _ rhs: Self) -> Bool { false }
}

extension SelmModel where Self: Equatable {
    public static func equals(_ lhs: Self, _ rhs: Self) -> Bool { lhs == rhs }
}

extension SelmModel {
    public func modified<Value>(_ keyPath: WritableKeyPath<Self, Value>, _ value: Value) -> Self {
        (write(keyPath)) { _ in value }(self)
    }
}
