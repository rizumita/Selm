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
    struct Model: SelmModel, Equatable {
        var stepInterval:     TimeInterval = 2.0
        var count:            Int          = 0
        var url:              String       = ""
        var historyPageModel: HistoryPage.Model
        var safariPageModel:  SafariPage.Model?
    }
    
    enum Msg {
        case historyPageMsg(HistoryPage.Msg)
        case safariPageMsg(SafariPage.Msg)
        case step(Step)
        case stepDelayed(Step)
        case stepDelayedTask(Step)
        case stepTimer(Step)
        case stepDelayedTaskFinished(Result<Step, Never>)
        case updateCount(Step)
        case showSafariPage
    }

    static var genStepPublisher: GenStepPublisherWithInterval = { _, _ in fatalError() }    // Needs DI

    static func initialize(stepInterval: TimeInterval = 2.0,
                           genStepPublisher: @escaping GenStepPublisherWithInterval = SelmSample.genStepWithTimer) -> () -> (Model, Cmd<Msg>) {
        self.genStepPublisher = genStepPublisher

        return {
            let (m, c) = HistoryPage.initialize()
            return (Model(stepInterval: stepInterval, historyPageModel: m), c.map(Msg.historyPageMsg))
        }
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
            
        case .safariPageMsg(let sMsg):
            guard let sModel = model.safariPageModel else { return (model, .none) }
            switch SafariPage.update(sMsg, sModel) {
            case (let m, let c, .noOp):
                return (model |> set(\.safariPageModel, m), c.map(Msg.safariPageMsg))
            case (_, let c, .dismiss):
                return (model |> set(\.safariPageModel, .none), c.map(Msg.safariPageMsg))
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
            
        case .stepDelayedTask(let step):
            return (
                model,
                stepTask(step: step)
                |> Task.attempt(toMsg: { .stepDelayedTaskFinished($0) })
            )

        case .stepDelayedTaskFinished(let result):
            switch result {
            case .success(let step):
                let newModel = model
                    |> set(\.count, step.step(count: model.count))
                    |> set(\.historyPageModel.history, model.historyPageModel.history + [step])
                return (newModel, .none)
            case .failure:
                return (model, .none)
            }
            
        case .updateCount(let step):
            return (model |> set(\.count, step.step(count: model.count)), .none)

        case .stepTimer(let step):
            return (
                model,
                stepTask(stepPublisher: self.genStepPublisher(step, model.stepInterval))
                |> Task.attempt(toMsg: { .stepDelayedTaskFinished($0) })
            )

        case .showSafariPage:
            let (m, c) = SafariPage.initialize(url: URL(string: "https://www.google.com")!)
            return (model |> set(\.safariPageModel, m), c.map(Msg.safariPageMsg))
        }
    }

    static func stepTask(step: Step) -> Task<Step, Never> {
        Task { fulfill in
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                fulfill(.success(step))
            }
        }
    }

    static func stepTask(stepPublisher: AnyPublisher<Step, Never>) -> Task<Step, Never> {
        Task { observer, cancellables in
            stepPublisher.sink { observer(.success($0)) }.store(in: &cancellables)
        }
    }
}

typealias GenStepPublisherWithInterval = (Step, TimeInterval) -> AnyPublisher<Step, Never>
private let genStepWithTimer: GenStepPublisherWithInterval = { step, interval in
    Timer.publish(every: interval, on: .main, in: .default)
         .autoconnect()
         .first()
         .map(const(step))
         .eraseToAnyPublisher()
}
