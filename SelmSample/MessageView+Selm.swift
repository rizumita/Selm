//
// Created by 和泉田 領一 on 2019/12/20.
//

import Foundation
import Selm

extension MessageViewController: SelmUIView {
    struct Model: Equatable {
        var message: String
    }

    enum Msg {
        case printMessage
        case dismiss
    }

    static let onAppearMsg: Msg! = .printMessage

    enum ExternalMsg {
        case noOp
        case dismiss
    }

    static func initialize(message: String) -> (Model, Cmd<Msg>) {
        (Model(message: message), .none)
    }

    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>, ExternalMsg) {
        switch msg {
        case .printMessage:
            return (model, .none, .noOp)

        case .dismiss:
            return (model, .none, .dismiss)
        }
    }
}
