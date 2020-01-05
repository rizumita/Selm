//
// Created by 和泉田 領一 on 2019-04-07.
//

import Foundation
import Combine

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public class Runner<View> where View: SelmView {
    private let update: SelmUpdate<View.Msg, View.Model>
    private let dispatcher    = Dispatcher<View.Msg>()
    private var store:  Store<View.Msg, View.Model>!
    private let dispatchQueue = DispatchQueue.main

    public static func create<Model>(initialize: @escaping SelmInit<View.Msg, Model>,
                              update: @escaping SelmUpdate<View.Msg, Model> = View.update) -> Store<View.Msg, View.Model> where Model == View.Model {
        let runner = Runner(initialize: initialize, update: update, equals: { _, _ in false })
        return runner.store
    }

    public static func create<Model>(initialize: @escaping SelmInit<View.Msg, Model>,
                                     update: @escaping SelmUpdate<View.Msg, Model> = View.update) -> Store<View.Msg, View.Model> where Model == View.Model, View.Model: Equatable {
        let runner = Runner(initialize: initialize, update: update, equals: ==)
        return runner.store
    }

    private init(initialize: @escaping () -> (View.Model, Cmd<View.Msg>),
                 update: @escaping (View.Msg, View.Model) -> (View.Model, Cmd<View.Msg>),
                 equals: @escaping (View.Model, View.Model) -> Bool) {
        self.update = update

        let (initialModel, cmd) = initialize()

        self.dispatcher.setDispatchThunk { msg in
            run(on: self.dispatchQueue) {
                self.process(msg)
            }
        }

        self.store = Store(model: initialModel, dispatch: self.dispatcher.dispatch, equals: equals)

        cmd.dispatch(self.dispatcher.dispatch)
    }

    private func process(_ msg: View.Msg) {
        let (updatedModel, newCommand) = update(msg, store.model)
        store.update(updatedModel)
        newCommand.dispatch(dispatcher.dispatch)
    }
}
