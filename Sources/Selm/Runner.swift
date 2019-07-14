//
// Created by 和泉田 領一 on 2019-04-07.
//

import Foundation

public class Runner<Model, Msg> {
    private let update:     SelmUpdate<Msg, Model>
    private let dispatcher = Dispatcher<Msg>()
    private var driver: Driver<Msg, Model>!
    private let dispatchQueue = DispatchQueue(label: "Selm.Runner.Queue")

    public static func create(initialize: @escaping SelmInit<Msg, Model>,
                              update: @escaping SelmUpdate<Msg, Model>) -> Driver<Msg, Model> {
        let runner = Runner(initialize: initialize, update: update)
        return runner.driver
    }

    private init(initialize: @escaping () -> (Model, Cmd<Msg>),
                 update: @escaping (Msg, Model) -> (Model, Cmd<Msg>)) {
        self.update = update

        let (initialModel, cmd) = initialize()
        
        self.dispatcher.setDispatchThunk { msg in
            self.dispatchQueue.async {
                self.process(msg)
            }
        }
        
        self.driver = Driver(model: initialModel, dispatch: self.dispatcher.dispatch)

        cmd.dispatch(self.dispatcher.dispatch)
    }

    private func process(_ msg: Msg) {
        let (updatedModel, newCommand) = update(msg, driver.model)
        driver.model = updatedModel
        newCommand.dispatch(dispatcher.dispatch)
    }
}
