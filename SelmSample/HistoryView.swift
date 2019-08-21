//
//  HistoryView.swift
//  SelmSample
//
//  Created by 和泉田 領一 on 2019/07/01.
//

import SwiftUI
import Combine
import Swiftx
import Operadics
import Selm

struct HistoryView : View {
    struct Model: Equatable {
        var history: [Step] = []
                
        static func ==(_ lhs: Model, _ rhs: Model) -> Bool {
            if lhs.history != rhs.history { return false }
            return true
        }
    }
    
    enum Msg {
        case add(Step)
        case remove(IndexSet)
    }
    
    enum ExtMsg {
        case noOp
        case updated(count: Int)
    }
    
    static func initialize() -> (Model, Cmd<Msg>) {
        (Model(), .none)
    }
    
    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>, ExtMsg) {
        switch msg {
        case .add(let step):
            return (model |> set(\.history, model.history + [step]), .none, .noOp)
            
        case .remove(let indexSet):
            var history = model.history
            indexSet.forEach { index in history.remove(at: index) }
            let count = history.reduce(0) { result, step in step.step(count: result) }
            return (model |> set(\.history, history), .none, .updated(count: count))
        }
    }
    
    @ObservedObject var driver: Driver<Msg, Model>
    
    var body: some View {
        VStack(spacing: 20.0) {
            List {
                ForEach(driver.model.history, id: \.self) { step in
                    Text(step.string)
                }.onDelete(perform: driver.dispatch • Msg.remove)
            }
        }
    }
}

#if DEBUG
struct HistoryView_Previews : PreviewProvider {
    static var previews: some View {
        HistoryView(driver: .init(model: .init(history: []), dispatch: { _ in }))
    }
}
#endif
