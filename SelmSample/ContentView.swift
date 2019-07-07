//
//  ContentView.swift
//  SelmSample
//
//  Created by 和泉田 領一 on 2019/07/01.
//

import SwiftUI
import Combine
import Swiftx
import Operadics
import Selm

enum Step: Equatable {
    case up
    case down
    
    func step(count: Int) -> Int {
        switch self {
        case .up: return count + 1
        case .down: return count - 1
        }
    }
    
    var string: String {
        switch self {
        case .up: return "Up"
        case .down: return "Down"
        }
    }
}

struct MainPage {
    class Model: BindableObject, Hashable {
        var didChange = PassthroughSubject<(), Never>()
        
        var count: Int = 0 { didSet { didChange.send(()) } }
        var history: [Step] = []
        var historyPageModel: HistoryPage.Model? = .none
        
        static func == (lhs: Model, rhs: Model) -> Bool {
            if lhs.count != rhs.count { return false }
            if lhs.history != rhs.history { return false }
            return true
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(count)
        }
    }
    
    enum Msg {
        case historyPageMsg(HistoryPage.Msg)
        case step(Step)
        case showHistory
        case asyncPrint(String)
    }
    
    static func initialize() -> (Model, Cmd<Msg>) {
        return (Model(), .none)
    }
    
    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>) {
        switch msg {
        case .historyPageMsg(let hpMsg):
            let (m, c, extMsg) = HistoryPage.update(hpMsg, model.historyPageModel!)
            switch extMsg {
            case .noOp:
                return (model |> set(\.historyPageModel, m), c.map(Msg.historyPageMsg))
            case .dismiss:
                return (model |> set(\.historyPageModel, .none), .none)
            }
            
        case .step(let step):
            return (model |> set(\.count, step.step(count: model.count)) |> set(\.history, model.history + [step]), .none)
            
        case .showHistory:
            let (m, c) = HistoryPage.initialize(history: model.history)
            return (model |> set(\.historyPageModel, m), .batch([.ofAsyncMsg { fulfill in fulfill(.asyncPrint("logging")) },
                                                                 c.map(Msg.historyPageMsg)]))
            
        case .asyncPrint(let log):
            print(log)
            return (model, .none)
        }
    }
}

struct ContentView : View, Hashable {
    @ObjectBinding var model: MainPage.Model
    var dispatch: Dispatch<MainPage.Msg>
    var detailLink = DynamicNavigationDestinationLink(id: \ContentView.model,
                                                      content: { data -> AnyView? in
                                                        guard let m = data.model.historyPageModel else { return .none }
                                                        return AnyView(HistoryView(model: m, dispatch: data.dispatch • MainPage.Msg.historyPageMsg))
    })
    @State var navView: AnyView?
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 20.0) {
                Spacer()
                
                HStack {
                    Stepper(onIncrement: {
                        self.dispatch(.step(.up))
                    }, onDecrement: {
                        self.dispatch(.step(.down))
                    }) {
                        Text(String(self.model.count))
                    }
                    .frame(width: 200.0, alignment: .center)
                }
                
                Spacer()
                
                Button(action: {
                    self.dispatch(.showHistory)
                }) {
                    NavigationLink(destination: Text("")) {
                        Text("Link")
                    }
                }
                
                Spacer()
            }
        }
    }
    
    static func == (lhs: ContentView, rhs: ContentView) -> Bool {
        if lhs.model != rhs.model { return false }
        return true
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(model)
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(model: MainPage.Model(), dispatch: { _ in })
    }
}
#endif

