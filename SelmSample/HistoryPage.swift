//
//  HistoryPage.swift
//  SelmSample
//
//  Created by 和泉田 領一 on 2019/08/24.
//

import Foundation
import Combine
import Swiftx
import Operadics
import Selm

struct HistoryPage: SelmPageExt {
    struct Model: SelmModel, Equatable {
        var selectedStepPageModelID: StepPage.Model.ID?
        var stepPageModels: [StepPage.Model] = []
    }

    enum Msg {
        case add(Step)
        case remove(IndexSet)
        case select(StepPage.Model.ID?)
        case stepPageMsg(StepPage.Model.ID, StepPage.Msg)
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
            let (m, c) = StepPage.initialize(step: step)
            return (model |> set(\.stepPageModels, model.stepPageModels + [m]),
                c.map { Msg.stepPageMsg(m.id, $0) },
                .noOp)

        case .remove(let indexSet):
            var stepPageModels = model.stepPageModels
            indexSet.forEach { index in stepPageModels.remove(at: index) }
            let count = stepPageModels.reduce(0) { result, model in model.step.step(count: result) }
            return (model |> set(\.stepPageModels, stepPageModels),
                .none,
                .updated(count: count))

        case .select(let id):
            return (model |> set(\.selectedStepPageModelID, id), .none, .noOp)

        case let .stepPageMsg(id, sMsg):
            guard let stepPageModel = model.stepPageModels.first(id: id) else { return (model, .none, .noOp) }
            var models = model.stepPageModels

            switch StepPage.update(sMsg, stepPageModel) {
            case let (m, c, .noOp):
                models[id: id] = m
                return (model |> set(\.stepPageModels, models), c.map { Msg.stepPageMsg(id, $0) }, .noOp)

            case let (m, c, .update):
                models[id: id] = m
                let count = models.reduce(0) { result, model in model.step.step(count: result) }
                return (model |> set(\.stepPageModels, models),
                    c.map { Msg.stepPageMsg(id, $0) },
                    .updated(count: count))

            case let (_, c, .remove):
                _ = models.remove(id: id)
                let count = models.reduce(0) { result, model in model.step.step(count: result) }
                return (model |> set(\.stepPageModels, models),
                    c.map { Msg.stepPageMsg(id, $0) },
                    .updated(count: count))
            }
        }
    }
}
