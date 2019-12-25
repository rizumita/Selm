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
    static var dependency: Dependency = Dependency()
    
    struct Dependency {
        var genStepPublisher: GenStepPublisherWithInterval = SelmSample.genStepWithTimer
    }
    
    struct Model: SelmModel, Equatable {
        var stepInterval:     TimeInterval = 2.0
        var count:            Int          = 0
        var url:              String       = ""
        var historyPageModel: HistoryPage.Model
        var safariPageModel:  SafariPage.Model?
        var messagePageModel: MessagePage.Model?
    }
    
    enum Msg {
        case historyPageMsg(HistoryPage.Msg)
        case safariPageMsg(SafariPage.Msg)
        case messagePageMsg(MessagePage.Msg)
        case step(Step)
        case stepDelayed(Step)
        case stepDelayedTask(Step)
        case stepTimer(Step)
        case stepTimerTwice(Step)
        case stepDelayedTaskFinished(Result<Step, Never>)
        case updateCount(Step)
        case showSafariPage
        case showMessagePage
    }

    static let initialize: SelmInit<Msg, Model> = {
        let (m, c) = HistoryPage.initialize()
        return (Model(historyPageModel: m), c.map(Msg.historyPageMsg))
    }

    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>) {
        switch msg {
        case .historyPageMsg(let hvMsg):
            switch HistoryPage.update(hvMsg, model.historyPageModel) {
            case (let m, let c, .noOp):
                return (model |> modify(\.historyPageModel, m),
                    c.map(Msg.historyPageMsg))
                
            case (let m, let c, .updated(count: let count)):
                return (model |> modify(\.historyPageModel, m) |> modify(\.count, count),
                        c.map(Msg.historyPageMsg))
            }

        case .safariPageMsg(let sMsg):
            guard let sModel = model.safariPageModel else { return (model, .none) }
            switch SafariPage.update(sMsg, sModel) {
            case (let m, let c, .noOp):
                return (model |> modify(\.safariPageModel, m), c.map(Msg.safariPageMsg))
            case (_, let c, .dismiss):
                return (model |> modify(\.safariPageModel, .none), c.map(Msg.safariPageMsg))
            }

        case .messagePageMsg(let mMsg):
            guard let mModel = model.messagePageModel else { return (model, .none) }
            switch MessagePage.update(mMsg, mModel) {
            case let (m, c, .noOp):
                return (model |> modify(\.messagePageModel, m), c.map(Msg.messagePageMsg))
            case let (_, c, .dismiss):
                return (model |> modify(\.messagePageModel, .none), c.map(Msg.messagePageMsg))
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
                let newModel = model |> modify(\.count, step.step(count: model.count))
                return (newModel, .ofMsg(.historyPageMsg(.add(step))))
            case .failure:
                return (model, .none)
            }
            
        case .updateCount(let step):
            return (model |> modify(\.count, step.step(count: model.count)), .none)

        case .stepTimer(let step):
            return (
                model,
                stepTask(stepPublisher: self.dependency.genStepPublisher(step, model.stepInterval))
                    |> Task.attempt(toMsg: { .stepDelayedTaskFinished($0) })
            )

        case .stepTimerTwice(let step):
            return (
                model,
                stepTask(stepPublisher: self.dependency.genStepPublisher(step, model.stepInterval))
                |> Task.attempt(toCmd: {
                    .batch([.ofMsg(.stepDelayedTaskFinished($0)), .ofMsg(.stepDelayedTaskFinished($0))])
                })
            )

        case .showSafariPage:
            let (m, c) = SafariPage.initialize(url: URL(string: "https://www.google.com")!)
            return (model |> modify(\.safariPageModel, m), c.map(Msg.safariPageMsg))

        case .showMessagePage:
            let (m, c) = MessagePage.initialize(message: "My Message")
            return (model |> modify(\.messagePageModel, m), c.map(Msg.messagePageMsg))
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
