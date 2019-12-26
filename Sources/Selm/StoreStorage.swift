//
// Created by 和泉田 領一 on 2019/12/27.
//

import Foundation

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
class StoreStorage<Model> {
    private var stores           = [PartialKeyPath < Model>: Any]()
    private var identifiedStores = [AnyHashable: Any]()
    private var queue            = DispatchQueue(label: "StoreStorage")

    func save<Store>(_ store: Store, forKeyPath keyPath: PartialKeyPath<Model>) {
        _ = queue.sync {
            stores[keyPath] = store
        }
    }

    func save<Store>(_ store: Store, forID id: AnyHashable) {
        _ = queue.sync {
            identifiedStores[id] = store
        }
    }

    func load(forKeyPath keyPath: PartialKeyPath<Model>) -> Any? {
        stores[keyPath]
    }

    func load(forID id: AnyHashable) -> Any? {
        identifiedStores[id]
    }

    func remove(forKeyPath keyPath: PartialKeyPath<Model>) {
        _ = queue.sync {
            stores.removeValue(forKey: keyPath)
        }
    }

    func remove(forID id: AnyHashable) {
        _ = queue.sync {
            identifiedStores.removeValue(forKey: id)
        }
    }
}
