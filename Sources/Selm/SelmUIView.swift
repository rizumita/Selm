//
// Created by 和泉田 領一 on 2019/12/20.
//

import Foundation
import UIKit

public protocol SelmUIView where Self: UIViewController {
    associatedtype Page: _SelmPage
    associatedtype Msg = Page.Msg
    associatedtype Model = Page.Model

    var store: Store<Page> { get }

    func onAppear()
    func onDisappear()
}

extension SelmUIView {
    public var model:    Page.Model { store.model }
    public var dispatch: Dispatch<Page.Msg> { store.dispatch }

    public func onAppear() {
        if let msg = Page.onAppearMsg {
            store.dispatch(msg)
        }
    }

    public func onDisappear() {
        if let msg = Page.onDisappearMsg {
            store.dispatch(msg)
        }
    }
}
