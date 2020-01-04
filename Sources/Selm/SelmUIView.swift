//
// Created by 和泉田 領一 on 2019/12/20.
//

import Foundation
import UIKit

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol SelmUIView: _SelmView {
    associatedtype Msg
    associatedtype Model

    static var subscribesOnAppear:      Bool { get }
    static var unsubscribesOnDisappear: Bool { get }
    static var onAppearMsg:             Msg! { get }
    static var onDisappearMsg:          Msg! { get }

    func onAppear()
    func onDisappear()
    func onDisappear(onDismiss: () -> ())
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension SelmUIView {
    public static var subscribesOnAppear:      Bool { true }
    public static var unsubscribesOnDisappear: Bool { true }
    public static var onAppearMsg:             Msg! { .none }
    public static var onDisappearMsg:          Msg! { .none }

    public var model:    Model { store.model }
    public var dispatch: Dispatch<Msg> { store.dispatch }

    public func onAppear() {
        if Self.subscribesOnAppear {
            self.store.subscribe()
        }

        if let msg = Self.onAppearMsg {
            store.dispatch(msg)
        }
    }

    public func onDisappear() {
        if Self.unsubscribesOnDisappear {
            self.store.unsubscribe()
        }

        if let msg = Self.onDisappearMsg {
            store.dispatch(msg)
        }
    }

    public func onDisappear(onDismiss: () -> ()) {
        onDisappear()
        onDismiss()
    }
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension SelmUIView where Self: UIViewController {
    public func onDisappear(onDismiss: () -> ()) {
        onDisappear()

        if (self.isMovingFromParent || self.isBeingDismissed) {
            onDismiss()
        }
    }
}
