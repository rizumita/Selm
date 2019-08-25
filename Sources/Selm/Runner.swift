//
// Created by 和泉田 領一 on 2019-04-07.
//

import Foundation

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public class Runner<Page> where Page: _SelmPage {
    private let update:     SelmUpdate<Page.Msg, Page.Model>
    private let dispatcher = Dispatcher<Page.Msg>()
    private var store: Store<Page>!
    private let dispatchQueue = DispatchQueue.main

    public static func create(initialize: @escaping SelmInit<Page.Msg, Page.Model>,
                              update: @escaping SelmUpdate<Page.Msg, Page.Model>) -> Store<Page> {
        let runner = Runner(initialize: initialize, update: update)
        return runner.store
    }

    private init(initialize: @escaping () -> (Page.Model, Cmd<Page.Msg>),
                 update: @escaping (Page.Msg, Page.Model) -> (Page.Model, Cmd<Page.Msg>)) {
        self.update = update

        let (initialModel, cmd) = initialize()
        
        self.dispatcher.setDispatchThunk { msg in
            self.dispatchQueue.async {
                self.process(msg)
            }
        }
        
        self.store = Store(model: initialModel, dispatch: self.dispatcher.dispatch)

        cmd.dispatch(self.dispatcher.dispatch)
    }

    private func process(_ msg: Page.Msg) {
        let (updatedModel, newCommand) = update(msg, store.model)
        store.update(updatedModel)
        newCommand.dispatch(dispatcher.dispatch)
    }
}
