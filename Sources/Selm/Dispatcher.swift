//
// Created by 和泉田 領一 on 2019-04-07.
//

import Foundation

class Dispatcher<Msg> {
    var dispatch: Dispatch<Msg> {
        return { msg in self.dispatchImpl(msg) }
    }

    private var dispatchImpl: Dispatch<Msg> = { msg in }

    func setDispatchThunk(_ v: @escaping Dispatch<Msg>) {
        dispatchImpl = v
    }
}
