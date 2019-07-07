//
// Created by 和泉田 領一 on 2019-04-07.
//

import Foundation


public class Runner<Model, Msg> {
    private let update:     SelmUpdate<Msg, Model>
    private let dispatcher = Dispatcher<Msg>()
    private var lastModel:  Model
    private let dispatchQueue = DispatchQueue(label: "Selm.Runner.Queue")

    public static func create(initialize: @escaping SelmInit<Msg, Model>,
                              update: @escaping SelmUpdate<Msg, Model>) -> (Model, Dispatch<Msg>) {
        let runner = Runner(initialize: initialize, update: update)
        return (runner.lastModel, runner.dispatcher.dispatch)
    }

    private init(initialize: @escaping () -> (Model, Cmd<Msg>),
                 update: @escaping (Msg, Model) -> (Model, Cmd<Msg>)) {
        self.update = update

        let (initialModel, cmd) = initialize()
        self.lastModel = initialModel
        
        self.dispatcher.setDispatchThunk { msg in
            self.dispatchQueue.sync {
                self.process(msg)
            }
        }

        cmd.dispatch(self.dispatcher.dispatch)
    }

    private func process(_ msg: Msg) {
        let (updatedModel, newCommand) = update(msg, lastModel)
        lastModel = updatedModel
        newCommand.value.forEach { (sub: Sub<Msg>) in sub(dispatcher.dispatch) }
    }
}
