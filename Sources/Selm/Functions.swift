//
// Created by 和泉田 領一 on 2019-04-08.
//

import Foundation

public func dependsOn<Item>() -> DependsOn<Item> {
    var oldItem: Item?
    return { item, f in
        defer { oldItem = item }
        guard oldItem != item else { return }
        f(item)
    }
}

public func dependsOn<Item1, Item2>() -> DependsOn2<Item1, Item2> {
    var oldItem1: Item1?
    var oldItem2: Item2?
    return { item1, item2, f in
        defer { (oldItem1, oldItem2) = (item1, item2) }
        guard oldItem1 != item1 || oldItem2 != item2 else { return }
        f(item1, item2)
    }
}
