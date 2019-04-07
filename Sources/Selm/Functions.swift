//
// Created by 和泉田 領一 on 2019-04-08.
//

import Foundation

public func dependsOn<Item: Equatable>(_ item: Item?) -> DependsOnOptional<Item> {
    var oldItem = item
    return { newItem, f in
        defer { oldItem = newItem }
        guard let newItem = newItem else { return }
        guard oldItem != newItem else { return }
        f(newItem)
    }
}

public func dependsOn<Item: Equatable>(_ item: Item) -> DependsOn<Item> {
    var oldItem = item
    return { newItem, f in
        guard oldItem != newItem else { return }
        oldItem = newItem
        f(newItem)
    }
}

public typealias ChangesOn<Item: Equatable> = (Item?, (Item?) -> ()) -> ()

public func changesOn<Item: Equatable>(_ item: Item?) -> ChangesOn<Item> {
    var oldItem = item
    return { newItem, f in
        guard oldItem != newItem else { return }
        oldItem = newItem
        f(newItem)
    }
}
