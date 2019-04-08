//
// Created by 和泉田 領一 on 2019-04-08.
//

import Foundation

public func dependsOn<Item: Equatable>() -> DependsOnOptional<Item> {
    var oldItem: Item?
    return { newItem, f in
        defer { oldItem = newItem }
        guard let newItem = newItem else { return }
        guard oldItem != newItem else { return }
        f(newItem)
    }
}

public func dependsOn<Item: Equatable>() -> DependsOn<Item> {
    var oldItem: Item?
    return { newItem, f in
        guard oldItem != newItem else { return }
        oldItem = newItem
        f(newItem)
    }
}

public func dependsOn<Item: Equatable, R>(defaultValue: R) -> DependsOnOptionalReturn<Item, R> {
    var oldItem: Item?
    return { newItem, f in
        defer { oldItem = newItem }
        guard let newItem = newItem else { return defaultValue }
        guard oldItem != newItem else { return defaultValue }
        return f(newItem)
    }
}

public func dependsOn<Item: Equatable, R>(defaultValue: R) -> DependsOnReturn<Item, R> {
    var oldItem: Item?
    return { newItem, f in
        guard oldItem != newItem else { return defaultValue }
        oldItem = newItem
        return f(newItem)
    }
}

public func changesOn<Item: Equatable>() -> ChangesOn<Item> {
    var oldItem: Item?
    return { newItem, f in
        guard oldItem != newItem else { return }
        oldItem = newItem
        f(newItem)
    }
}
