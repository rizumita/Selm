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

    static var subscribesOnAppear:   Bool { get }
    static var unsubscribesOnDisappear: Bool { get }
    static var onAppearMsg:             Msg? { get }
    static var onDisappearMsg:          Msg? { get }
}

extension _SelmPage {
    public static var subscribesOnAppear: Bool { true }
    public static var unsubscribesOnDisappear: Bool { true }
    public static var onAppearMsg:    Msg? { .none }
    public static var onDisappearMsg: Msg? { .none }
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
    associatedtype ViewType: View

    var store: Store<Page> { get }

    var content: ViewType { get }
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)

extension SelmView {
    
    public var content: some View {
        // I did this to prevent changing every view right now
        // In the final implementation, this would be a requiement of conforming to SelmView
        return Text("Hello, world")
    }
    
    public var body: some View {
        return content
            .onAppear {
                if Page.subscribesOnAppear {
                    self.store.subscribe()
                }

                if let onAppearMsg = Page.onAppearMsg {
                    self.store.dispatch(onAppearMsg)
                }
            }
            .onDisappear {
                if Page.unsubscribesOnDisappear {
                    self.store.unsubscribe()
                }

                if let onDisappearMsg = Page.onDisappearMsg {
                    self.store.dispatch(onDisappearMsg)
                }
            }
    }

}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension SelmView {
    public var model:    Page.Model { store.model }
    public var dispatch: Dispatch<Page.Msg> { store.dispatch }
}
