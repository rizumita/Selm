//
// Created by 和泉田 領一 on 2019-04-23.
//

#if os(iOS)

import UIKit

extension UIViewController {
    @objc func swizzViewDidLoad() {
        swizzViewDidLoad()

        willChangeValue(for: \UIViewController.isViewLoaded)
        didChangeValue(for: \UIViewController.isViewLoaded)
    }

    @objc func swizzViewDidDisappear(_ animated: Bool) {
        swizzViewDidDisappear(animated)

        willChangeValue(for: \UIViewController.isMovingFromParent)
        didChangeValue(for: \UIViewController.isMovingFromParent)
    }
}

#endif
