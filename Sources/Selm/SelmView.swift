//
// Created by 和泉田 領一 on 2019/12/20.
//

import Foundation
import SwiftUI

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol _SelmView {
    associatedtype Msg
    associatedtype Model

    static var subscribesOnAppear:      Bool { get }
    static var unsubscribesOnDisappear: Bool { get }
    static var onAppearMsg:             Msg! { get }
    static var onDisappearMsg:          Msg! { get }

    var store: Store<Msg, Model> { get }
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension _SelmView {
    public static var subscribesOnAppear:      Bool { true }
    public static var unsubscribesOnDisappear: Bool { true }
    public static var onAppearMsg:             Msg! { .none }
    public static var onDisappearMsg:          Msg! { .none }

    public var model:    Self.Model { store.model }
    public var dispatch: Dispatch<Self.Msg> { store.dispatch }

    public static func modify<Value>(_ model: Model,
                                     _ keyPath: WritableKeyPath<Model, Value>,
                                     _ value: Value) -> Model {
        var model = model
        model[keyPath: keyPath] = value
        return model
    }

    public static func modify(_ model: Model, @ModifyBuilder _ block: () -> (Model) -> (Model)) -> Model {
        block()(model)
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
