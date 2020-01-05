//
//  ContentView+Selm.swift
//  SelmSample
//
//  Created by 和泉田 領一 on 2019/08/24.
//

import Foundation
import Combine
import Swiftx
import Operadics
import Selm

extension ContentView: SelmView {
    static var dependency: Dependency = Dependency()

    struct Dependency {
        var genStepPublisher: GenStepPublisherWithInterval = SelmSample.genStepWithTimer
    }

    struct Model: Equatable {
        var stepInterval:     TimeInterval = 2.0
        var count:            Int          = 0
        var url:              String       = ""
        var historyViewModel: HistoryView.Model
        var safariViewModel:  SafariView.Model?
        var messageViewModel: MessageViewController.Model?
    }

    enum Msg {
        case historyViewMsg(HistoryView.Msg)
        case safariViewMsg(SafariView.Msg)
        case messageViewMsg(MessageViewController.Msg)
        case step(Step)
        case stepDelayed(Step)
        case stepDelayedTask(Step)
        case stepTimer(Step)
        case stepTimerTwice(Step)
        case stepDelayedTaskFinished(Result<Step, Never>)
        case updateCount(Step)
        case showSafariView
        case showMessageView
    }

    static let initialize: SelmInit<Msg, Model> = {
        let (m, c) = HistoryView.initialize()
        return (Model(historyViewModel: m), c.map(Msg.historyViewMsg))
    }

    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>) {
        switch msg {
        case .historyViewMsg(let hvMsg):
            switch HistoryView.update(hvMsg, model.historyViewModel) {
            case (let m, let c, .noOp):
                return (modify(model, \.historyViewModel, m),
                    c.map(Msg.historyViewMsg))

            case (let m, let c, .updated(count: let count)):
                return (
                    modify(model) {
                        (\Model.historyViewModel, m)
                        (\Model.count, count)
                    },
                    c.map(Msg.historyViewMsg))
            }

        case .safariViewMsg(let sMsg):
            guard let sModel = model.safariViewModel else { return (model, .none) }
            switch SafariView.update(sMsg, sModel) {
            case (let m, let c, .noOp):
                return (modify(model, \.safariViewModel, m), c.map(Msg.safariViewMsg))
            case (_, let c, .dismiss):
                return (modify(model, \.safariViewModel, .none), c.map(Msg.safariViewMsg))
            }

        case .messageViewMsg(let mMsg):
            guard let mModel = model.messageViewModel else { return (model, .none) }
            switch MessageViewController.update(mMsg, mModel) {
            case let (m, c, .noOp):
                return (modify(model, \.messageViewModel, m), c.map(Msg.messageViewMsg))
            case let (_, c, .dismiss):
                return (modify(model, \.messageViewModel, .none), c.map(Msg.messageViewMsg))
            }

        case .step(let step):
            return (model,
                .batch([.ofMsg(.updateCount(step)),
                        .ofMsg(.historyViewMsg(.add(step)))]))

        case .stepDelayed(let step):
            return (model,
                .ofAsyncCmd { fulfill in
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                            .batch([.ofMsg(.updateCount(step)),
                                    .ofMsg(.historyViewMsg(.add(step)))])
                            |> fulfill
                        }
                    })
            
        case .stepDelayedTask(let step):
            return (
                model,
                stepTask(step: step).attemptToMsg { .stepDelayedTaskFinished($0) }
            )

        case .stepDelayedTaskFinished(let result):
            switch result {
            case .success(let step):
                let newModel = modify(model, \.count, step.step(count: model.count))
                return (newModel, .ofMsg(.historyViewMsg(.add(step))))
            case .failure:
                return (model, .none)
            }
            
        case .updateCount(let step):
            return (modify(model, \.count, step.step(count: model.count)), .none)

        case .stepTimer(let step):
            return (
                model,
                Task(self.dependency.genStepPublisher(step, model.stepInterval))
                    .attemptToMsg { .stepDelayedTaskFinished($0) }
            )

        case .stepTimerTwice(let step):
            return (
                model,
                Task(self.dependency.genStepPublisher(step, model.stepInterval))
                    .attemptToCmd {
                        .batch([.ofMsg(.stepDelayedTaskFinished($0)), .ofMsg(.stepDelayedTaskFinished($0))])
                    }
            )

        case .showSafariView:
            let (m, c) = SafariView.initialize(url: URL(string: "https://www.google.com")!)
            return (modify(model, \.safariViewModel, m), c.map(Msg.safariViewMsg))

        case .showMessageView:
            let (m, c) = MessageViewController.initialize(message: "My Message")
            return (modify(model, \.messageViewModel, m), c.map(Msg.messageViewMsg))
        }
    }

    static func stepTask(step: Step) -> Task<Step, Never> {
        Task { fulfill in
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                fulfill(.success(step))
            }
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
