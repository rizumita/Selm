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
        var history: [Step] = []
    }
    
    enum Msg {
        case add(Step)
        case remove(IndexSet)
    }
    
    enum ExternalMsg {
        case noOp
        case updated(count: Int)
    }
    
    static func initialize() -> (Model, Cmd<Msg>) {
        (Model(), .none)
    }
    
    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>, ExternalMsg) {
        switch msg {
        case .add(let step):
            return (model |> set(\.history, model.history + [step]),
                    .none,
                    .noOp)
            
        case .remove(let indexSet):
            var history = model.history
            indexSet.forEach { index in history.remove(at: index) }
            let count = history.reduce(0) { result, step in step.step(count: result) }
            return (model |> set(\.history, history),
                    .none,
                    .updated(count: count))
        }
    }
}
