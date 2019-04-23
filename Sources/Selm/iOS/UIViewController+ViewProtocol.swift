//
// Created by 和泉田 領一 on 2019-04-23.
//

import Foundation

#if os(iOS)
import UIKit

extension UIViewController {
    public var isAboutToClose: Bool {
        return self.isBeingDismissed
               || self.isMovingFromParent
               || self.navigationController?.isBeingDismissed
                  ?? false
    }
}

#endif
