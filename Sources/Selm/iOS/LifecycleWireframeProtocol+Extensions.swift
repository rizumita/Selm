//
// Created by 和泉田 領一 on 2019-04-23.
//

#if os(iOS)
import UIKit

var swizzle: () = {
    if let originalMethod = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.viewDidLoad)),
       let swizzlingMethod = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.swizzViewDidLoad)) {
        method_exchangeImplementations(originalMethod, swizzlingMethod)
    }
    if let originalMethod = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.viewDidDisappear)),
       let swizzlingMethod = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.swizzViewDidDisappear)) {
        method_exchangeImplementations(originalMethod, swizzlingMethod)
    }
    return
}()

extension LifecycleWireframeProtocol {
    public func observeLifecycle(viewController: UIViewController, dispatch: @escaping Dispatch<Msg>) {
        _ = swizzle

        if let msg = Msg.loadedMsg {
            var observation: LifecycleObservation!
            observation = LifecycleObservation(wireframe: self,
                                               msg: msg,
                                               observation: viewController.observe(
                                                   \.isViewLoaded,
                                                   options: [.new]) {
                                                   [weak viewController] _, change in
                                                   if viewController?.isViewLoaded == true {
                                                       dispatch(msg)
                                                       guard let index = lifecycleObservations.firstIndex(of: observation) else { return }
                                                       lifecycleObservations.remove(at: index)
                                                   }
                                               })
            lifecycleObservations.append(observation)
        }

        if let msg = Msg.dismissingMsg {
            var observation: LifecycleObservation!
            observation = LifecycleObservation(wireframe: self,
                                               msg: msg,
                                               observation: viewController.observe(\UIViewController.isMovingFromParent,
                                                                                   options: [.new]) {
                                                   [weak viewController] _, change in
                                                   if viewController?.isAboutToClose == true {
                                                       dispatch(msg)
                                                       guard let index = lifecycleObservations.firstIndex(of: observation) else { return }
                                                       lifecycleObservations.remove(at: index)
                                                   }
                                               })
            lifecycleObservations.append(observation)
        }
    }
}
#endif
