//
// Created by 和泉田 領一 on 2019/12/19.
//

import Foundation
import Selm

extension StepView: SelmViewExt {
    struct Model: Hashable, Identifiable {
        var id = UUID()
        var step: Step
    }

    enum Msg {
        case toggle
        case remove
    }

    enum ExternalMsg {
        case noOp
        case update
        case remove
    }

    static func initialize(step: Step) -> (Model, Cmd<Msg>) {
        (Model(step: step), .none)
    }

    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>, ExternalMsg) {
        switch msg {
        case .toggle:
            return (modify(model, \.step, model.step.toggled), .none, .update)
        case .remove:
            return (model, .none, .remove)
        }
    }
}
