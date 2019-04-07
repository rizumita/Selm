//
// Created by 和泉田 領一 on 2019-04-07.
//

import Foundation

public class Runner<Model, Msg> {
    private let initialize: () -> (Model, Cmd<Msg>)
    private let update:     SelmUpdate<Msg, Model>
    private let view:       SelmView<Msg, Model>
    private let dispatcher = Dispatcher<Msg>()
    private var lastModel:  Model

    public static func create(initialize: @escaping () -> (Model, Cmd<Msg>),
                              update: @escaping SelmUpdate<Msg, Model>,
                              view: @escaping SelmView<Msg, Model>) -> Dispatch<Msg> {
        let runner = Runner(initialize: initialize, update: update, view: view)
        return { msg in runner.dispatcher.dispatch(msg) }
    }

    private init(initialize: @escaping () -> (Model, Cmd<Msg>),
                 update: @escaping (Msg, Model) -> (Model, Cmd<Msg>),
                 view: @escaping SelmView<Msg, Model>) {
        self.initialize = initialize
        self.update = update
        self.view = view

        let (initialModel, cmd) = self.initialize()
        self.lastModel = initialModel

        self.dispatcher.setDispatchThunk { [weak self] msg in
            DispatchQueue.main.async {
                self?.process(msg)
            }
        }

        cmd.dispatch(self.dispatcher.dispatch)
    }

    private func process(_ msg: Msg) {
        let (updatedModel, newCommand) = update(msg, lastModel)
        lastModel = updatedModel
        view(updatedModel, self.dispatcher.dispatch)
        newCommand.value.forEach { (sub: Sub<Msg>) in sub(dispatcher.dispatch) }
    }
}
