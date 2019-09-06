//
//  ContentPage.swift
//  SelmSample
//
//  Created by 和泉田 領一 on 2019/08/24.
//

import Foundation
import Combine
import Swiftx
import Operadics
import Selm

struct ContentPage: SelmPage {
    struct Model: Equatable {
        var count: Int = 0
        var url: String = ""
        var historyPageModel: HistoryPage.Model
        
        static func == (lhs: Model, rhs: Model) -> Bool {
            if lhs.count != rhs.count { return false }
            return true
        }
    }
    
    enum Msg {
        case historyPageMsg(HistoryPage.Msg)
        case step(Step)
        case stepDelayed(Step)
        case updateCount(Step)
    }
    
    static func initialize() -> (Model, Cmd<Msg>) {
        let (m, c) = HistoryPage.initialize()
        return (Model(historyPageModel: m), c.map(Msg.historyPageMsg))
    }
    
    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>) {
        switch msg {
        case .historyPageMsg(let hvMsg):
            switch HistoryPage.update(hvMsg, model.historyPageModel) {
            case (let m, let c, .noOp):
                return (model |> set(\.historyPageModel, m),
                        c.map(Msg.historyPageMsg))
                
            case (let m, let c, .updated(count: let count)):
                return (model |> set(\.historyPageModel, m) |> set(\.count, count),
                        c.map(Msg.historyPageMsg))
            }
            
        case .step(let step):
            return (model,
                    .batch([.ofMsg(.updateCount(step)),
                            .ofMsg(.historyPageMsg(.add(step)))]))
            
        case .stepDelayed(let step):
            return (model,
                    .ofAsyncCmd { fulfill in
                        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                            .batch([.ofMsg(.updateCount(step)),
                                    .ofMsg(.historyPageMsg(.add(step)))])
                            |> fulfill
                        }
                    })
            
        case .updateCount(let step):
            return (model |> set(\.count, step.step(count: model.count)), .none)
        }
    }
}
