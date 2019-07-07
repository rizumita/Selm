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

struct HistoryPage {
    class Model: BindableObject, Equatable {
        var didChange = PassthroughSubject<(), Never>()
        
        var history: [Step]

        var safariPageModel: SafariPage.Model? {
            didSet { didChange.send(()) }
        }
        
        init(history: [Step]) { self.history = history }
        
        static func ==(_ lhs: Model, _ rhs: Model) -> Bool {
            if lhs.history != rhs.history { return false }
            return true
        }
    }
    
    enum Msg {
        case safariPageMsg(SafariPage.Msg)
        case showWeb(URL)
        case onDisappear
    }
    
    enum ExternalMsg {
        case noOp
        case dismiss
    }
    
    static func initialize(history: [Step]) -> (Model, Cmd<Msg>) {
        (Model(history: history), .none)
    }
    
    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>, ExternalMsg) {
        switch msg {
        case .safariPageMsg(let spMsg):
            let (m, c, extMsg) = SafariPage.update(spMsg, model.safariPageModel!)
            switch extMsg {
            case .noOp:
                return (model |> set(\.safariPageModel, m), c.map(Msg.safariPageMsg), .noOp)
            case .dismiss:
                return (model |> set(\.safariPageModel, .none), .none, .noOp)
            }
            
        case .showWeb(let url):
            let (m, c) = SafariPage.initialize(url: url)
            return (model |> set(\.safariPageModel, m), c.map(Msg.safariPageMsg), .noOp)
            
        case .onDisappear:
            return (model, .none, .dismiss)
        }
    }
}

struct HistoryView : View {
    @ObjectBinding var model: HistoryPage.Model
    var dispatch: Dispatch<HistoryPage.Msg>
    
    var body: some View {
        VStack(spacing: 20.0) {
            List {
                ForEach(model.history.identified(by: \.self)) { step in
                    Text(step.string)
                }
            }
            
//            Button(action: {
//                self.dispatch(.showWeb(URL(string: "https://google.com")!))
//            }) {
//                Text("Show web")
//                }.presentation(self.model.safariPageModel == nil ? nil : Modal(SafariView(model: self.model.safariPageModel!, dispatch: self.dispatch • DetailPage.Msg.safariPageMsg)))
//            }.onDisappear {
//                self.dispatch(.onDisappear)
            }
    }
    
    var safariView: some View {
        let safariViewDispatch = self.dispatch • HistoryPage.Msg.safariPageMsg
        let view = SafariView(model: self.model.safariPageModel!, dispatch: safariViewDispatch)
        return view.onDisappear {
            safariViewDispatch(.onDisappear)
        }
    }
}

#if DEBUG
struct HistoryView_Previews : PreviewProvider {
    static var previews: some View {
        HistoryView(model: .init(history: []), dispatch: { _ in })
    }
}
#endif
