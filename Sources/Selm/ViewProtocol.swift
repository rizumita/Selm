//
// Created by 和泉田 領一 on 2019-04-23.
//

import Foundation

public protocol LifecycleViewProtocol: class {
    var isViewLoaded:   Bool { get }
    var isAboutToClose: Bool { get }
}
