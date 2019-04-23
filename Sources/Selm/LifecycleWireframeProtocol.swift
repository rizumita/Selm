//
// Created by 和泉田 領一 on 2019-04-23.
//

import Foundation

public protocol LifecycleWireframeProtocol {
    associatedtype Msg: LifecycleMsgProtocol
    associatedtype View: LifecycleViewProtocol

    func showView(dispatch: @escaping Dispatch<Msg>) -> View
}
