//
//  Functions.swift
//  SelmSample
//
//  Created by 和泉田 領一 on 2019/07/01.
//

import Foundation

public func write<Item, Value>(_ keyPath: WritableKeyPath<Item, Value>) -> (@escaping (Value) -> Value) -> (Item) -> Item {
    return { update in
        return { item in
            var item = item
            item[keyPath: keyPath] = update(item[keyPath: keyPath])
            return item
        }
    }
}

public func set<Item, Value>(_ keyPath: WritableKeyPath<Item, Value>, _ value: Value) -> (Item) -> Item {
    return (write(keyPath)) { _ in value }
}

public func get<Item, Value>(_ keyPath: KeyPath<Item, Value>) -> (Item) -> Value {
    return { item in item[keyPath: keyPath] }
}
