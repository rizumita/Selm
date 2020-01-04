//
// Created by 和泉田 領一 on 2019/12/20.
//

import Foundation
import SwiftUI

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol _SelmView {
    associatedtype Msg
    associatedtype Model

    var store: Store<Self> { get }
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension _SelmView {
    public var model:    Self.Model { store.model }
    public var dispatch: Dispatch<Self.Msg> { store.dispatch }

    public static func modify<Value>(_ keyPath: WritableKeyPath<Model, Value>, _ value: Value) -> (Model) -> Model {
        (write(keyPath)) { _ in value }
    }
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol SelmView: _SelmView, View {
    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>)
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol SelmViewExt: _SelmView, View {
    associatedtype ExternalMsg

    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>, ExternalMsg)
}
