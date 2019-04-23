//
// Created by 和泉田 領一 on 2019-04-23.
//

import Foundation

class LifecycleObservation: NSObject {
    let wireframe:   Any
    let msg:         Any
    let observation: NSKeyValueObservation

    init(wireframe: Any, msg: Any, observation: NSKeyValueObservation) {
        self.wireframe = wireframe
        self.msg = msg
        self.observation = observation
        super.init()
    }
}

var lifecycleObservations = [LifecycleObservation]()
