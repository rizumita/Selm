//
//  HistoryView+Selm.swift
//  SelmSample
//
//  Created by 和泉田 領一 on 2019/08/24.
//

import Foundation
import Combine
import Swiftx
import Operadics
import Selm

extension HistoryView: SelmViewExt {
    struct Model: SelmModel, Equatable {
        var selectedStepViewModelID: StepView.Model.ID?
        var stepViewModels:          [StepView.Model] = []
    }

    enum Msg {
        case add(Step)
        case remove(IndexSet)
        case select(StepView.Model.ID?)
        case stepPageMsg(StepView.Model.ID, StepView.Msg)
    }
    
    enum ExternalMsg {
        case noOp
        case updated(count: Int)
    }
    
    static func initialize() -> (Model, Cmd<Msg>) {
        (Model(), .none)
    }
    
    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>, ExternalMsg) {
        dump(msg)
        switch msg {
        case .add(let step):
            let (m, c) = StepView.initialize(step: step)
            return (model |> modify(\.stepViewModels, model.stepViewModels + [m]),
                c.map { Msg.stepPageMsg(m.id, $0) },
                .noOp)

        case .remove(let indexSet):
            var stepPageModels = model.stepViewModels
            indexSet.forEach { index in stepPageModels.remove(at: index) }
            let count = stepPageModels.reduce(0) { result, model in model.step.step(count: result) }
            return (model |> modify(\.stepViewModels, stepPageModels),
                .none,
                .updated(count: count))

        case .select(let id):
            return (model |> modify(\.selectedStepViewModelID, id), .none, .noOp)

        case let .stepPageMsg(id, sMsg):
            guard let stepPageModel = model.stepViewModels.first(id: id) else { return (model, .none, .noOp) }
            var models = model.stepViewModels

            switch StepView.update(sMsg, stepPageModel) {
            case let (m, c, .noOp):
                models[id: id] = m
                return (model |> modify(\.stepViewModels, models), c.map { Msg.stepPageMsg(id, $0) }, .noOp)

            case let (m, c, .update):
                models[id: id] = m
                let count = models.reduce(0) { result, model in model.step.step(count: result) }
                return (model |> modify(\.stepViewModels, models),
                    c.map { Msg.stepPageMsg(id, $0) },
                    .updated(count: count))

            case let (_, c, .remove):
                _ = models.remove(id: id)
                let count = models.reduce(0) { result, model in model.step.step(count: result) }
                return (model |> modify(\.stepViewModels, models),
                    c.map { Msg.stepPageMsg(id, $0) },
                    .updated(count: count))
            }
        }
    }
}
