//
// Created by 和泉田 領一 on 2019/12/19.
//

import Foundation

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Array where Element: Identifiable {
    public func first(id: Element.ID) -> Element? {
        first { $0.id == id }
    }

    public func firstIndex(id: Element.ID) -> Index? {
        firstIndex { $0.id == id }
    }

    public mutating func remove(id: Element.ID) -> Element {
        guard let index = firstIndex(id: id) else { fatalError("No element of ID: \(id)") }
        return remove(at: index)
    }

    public subscript(id id: Element.ID) -> Element? {
        get {
            first(id: id)
        }
        set {
            guard let index = firstIndex(id: id),
                  let element = newValue
                else { return }
            self[index] = element
        }
    }
}
