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
        var safariPageModel: SafariPage.Model?
        
        static func == (lhs: Model, rhs: Model) -> Bool {
            if lhs.count != rhs.count { return false }
            return true
        }
    }
    
    enum Msg {
        case historyPageMsg(HistoryPage.Msg)
        case safariPageMsg(SafariPage.Msg)
        case step(Step)
        case setURL(String)
        case showWeb
        case hideWeb
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
                return (model |> set(\.historyPageModel, m), c.map(Msg.historyPageMsg))
            case (let m, let c, .updated(count: let count)):
                return (model |> set(\.historyPageModel, m) |> set(\.count, count), c.map(Msg.historyPageMsg))
            }
            
        case .safariPageMsg(let spMsg):
            switch SafariPage.update(spMsg, model.safariPageModel!) {
            case (let m, let c, .noOp):
                return (model |> set(\.safariPageModel, m), c.map(Msg.safariPageMsg))
            case (_, _, .dismiss):
                return (model |> set(\.safariPageModel, .none), .none)
            }
            
        case .step(let step):
            return (model |> set(\.count, step.step(count: model.count)),
                    .ofMsg(.historyPageMsg(.add(step))))
            
        case .setURL(let urlString):
            return (model |> set(\.url, urlString), .none)
            
        case .showWeb:
            guard let url = URL(string: model.url) else { return (model, .none) }
            let (m, c) = SafariPage.initialize(url: url)
            return (model |> set(\.safariPageModel, m), c.map(Msg.safariPageMsg))
            
        case .hideWeb:
            return (model |> set(\.safariPageModel, .none), .none)
        }
    }
}
