//
// Created by 和泉田 領一 on 2019-04-23.
//

import Foundation

public protocol LifecycleMsgProtocol {
    static var loadedMsg:     Self? { get }
    static var dismissingMsg: Self? { get }
}

extension LifecycleMsgProtocol {
    public static var loadedMsg:     Self? { return .none }
    public static var dismissingMsg: Self? { return .none }
}
