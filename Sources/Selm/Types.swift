//
// Created by 和泉田 領一 on 2019-04-07.
//

import Foundation
import SwiftUI

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public typealias SelmInit<Msg, Model> = () -> (Model, Cmd<Msg>)
@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public typealias SelmUpdate<Msg, Model> = (Msg, Model) -> (Model, Cmd<Msg>)
public typealias Dispatch<Msg> = (Msg) -> ()
public typealias Sub<Msg> = (@escaping Dispatch<Msg>) -> ()
public typealias DependsOn<Item: Equatable> = (Item, (Item) -> ()) -> ()
public typealias DependsOn2<Item1: Equatable, Item2: Equatable> = (Item1, Item2, ((Item1, Item2)) -> ()) -> ()
public typealias DependsOn3<Item1: Equatable, Item2: Equatable, Item3: Equatable> = (Item1, Item2, Item3, ((Item1, Item2, Item3)) -> ()) -> ()

public protocol _SelmPage {
    associatedtype Msg
    associatedtype Model: SelmModel
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

public protocol SelmModel {
    static func equals(_ lhs: Self, _ rhs: Self) -> Bool
}

extension SelmModel {
    public static func equals(_ lhs: Self, _ rhs: Self) -> Bool { false }
}

extension SelmModel where Self: Equatable {
    public static func equals(_ lhs: Self, _ rhs: Self) -> Bool { lhs == rhs }
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol SelmView: View {
    associatedtype Page: _SelmPage
    associatedtype Msg = Page.Msg
    associatedtype Model = Page.Model

    var store: Store<Page> { get }
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension SelmView {
    public var model: Page.Model { store.model }
    public var dispatch: Dispatch<Page.Msg> { store.dispatch }
}
