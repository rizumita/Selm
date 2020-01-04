//
// Created by 和泉田 領一 on 2020/01/04.
//

import Foundation

@_functionBuilder public struct ModifyBuilder {
    public static func buildBlock<Root, T1>(
        _ kt1: (WritableKeyPath<Root, T1>, T1)) -> (Root) -> Root {
        { root in
            var root = root
            root[keyPath: kt1.0] = kt1.1
            return root
        }
    }

    public static func buildBlock<Root, T1, T2>(
        _ kt1: (WritableKeyPath<Root, T1>, T1),
        _ kt2: (WritableKeyPath<Root, T2>, T2)) -> (Root) -> Root {
        { root in
            var root = root
            root[keyPath: kt1.0] = kt1.1
            root[keyPath: kt2.0] = kt2.1
            return root
        }
    }

    public static func buildBlock<Root, T1, T2, T3>(
        _ kt1: (WritableKeyPath<Root, T1>, T1),
        _ kt2: (WritableKeyPath<Root, T2>, T2),
        _ kt3: (WritableKeyPath<Root, T3>, T3)) -> (Root) -> Root {
        { root in
            var root = root
            root[keyPath: kt1.0] = kt1.1
            root[keyPath: kt2.0] = kt2.1
            root[keyPath: kt3.0] = kt3.1
            return root
        }
    }

    public static func buildBlock<Root, T1, T2, T3, T4>(
        _ kt1: (WritableKeyPath<Root, T1>, T1),
        _ kt2: (WritableKeyPath<Root, T2>, T2),
        _ kt3: (WritableKeyPath<Root, T3>, T3),
        _ kt4: (WritableKeyPath<Root, T4>, T4)) -> (Root) -> Root {
        { root in
            var root = root
            root[keyPath: kt1.0] = kt1.1
            root[keyPath: kt2.0] = kt2.1
            root[keyPath: kt3.0] = kt3.1
            root[keyPath: kt4.0] = kt4.1
            return root
        }
    }
}
