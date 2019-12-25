//
// Created by 和泉田 領一 on 2019/12/20.
//

import Foundation

public protocol _SelmPage {
    associatedtype Msg
    associatedtype Model: SelmModel

    static var subscribesOnAppear:      Bool { get }
    static var unsubscribesOnDisappear: Bool { get }
    static var onAppearMsg:             Msg! { get }
    static var onDisappearMsg:          Msg! { get }
}

extension _SelmPage {
    public static var subscribesOnAppear:      Bool { true }
    public static var unsubscribesOnDisappear: Bool { true }
    public static var onAppearMsg:             Msg! { .none }
    public static var onDisappearMsg:          Msg! { .none }

    public static func modify<Value>(_ keyPath: WritableKeyPath<Model, Value>, _ value: Value) -> (Model) -> Model {
        (write(keyPath)) { _ in value }
    }
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol SelmPage: _SelmPage {
    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>)
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol SelmPageExt: _SelmPage {
    associatedtype ExternalMsg

    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>, ExternalMsg)
}
