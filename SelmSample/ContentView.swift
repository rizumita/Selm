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

struct ContentView : View, Hashable {
    struct Model: Hashable {
        var count: Int = 0
        var history: [Step] = []
        var url: String = ""
        var historyViewModel: HistoryView.Model = .init(history: [])
        var safariViewModel: SafariView.Model?
        
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
        case historyViewMsg(HistoryView.Msg)
        case safariViewMsg(SafariView.Msg)
        case step(Step)
        case showHistory
        case setURL(String)
        case showWeb
    }
    
    static func initialize() -> (Model, Cmd<Msg>) {
        return (Model(), .none)
    }
    
    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>) {
        switch msg {
        case .historyViewMsg(let hvMsg):
            switch HistoryView.update(hvMsg, model.historyViewModel) {
            case (let m, let c, .noOp):
                return (model |> set(\.historyViewModel, m), c.map(Msg.historyViewMsg))
            case (_, _, .dismiss):
                return (model |> set(\.historyViewModel, .init(history: [])), .none)
            }
            
        case .safariViewMsg(let spMsg):
            switch SafariView.update(spMsg, model.safariViewModel!) {
            case (let m, let c, .noOp):
                return (model |> set(\.safariViewModel, m), c.map(Msg.safariViewMsg))
            case (_, _, .dismiss):
                return (model |> set(\.safariViewModel, .none), .none)
            }
            
        case .step(let step):
            let history = model.history + [step]
            return (model
                |> set(\.count, step.step(count: model.count))
                |> set(\.history, history)
                |> set(\.historyViewModel.history, history),
                    .none)
            
        case .showHistory:
            let (m, c) = HistoryView.initialize(history: model.history)
            return (model |> set(\.historyViewModel, m),
                    .batch([
                        .ofAsyncMsg { fulfill in
                            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) { fulfill(.step(.down)) }
                        },
                        c.map(Msg.historyViewMsg)
                    ]))
            
        case .setURL(let urlString):
            return (model |> set(\.url, urlString), .none)
            
        case .showWeb:
            guard let url = URL(string: model.url) else { return (model, .none) }
            let (m, c) = SafariView.initialize(url: url)
            return (model |> set(\.safariViewModel, m), c.map(Msg.safariViewMsg))
        }
    }
    
    @ObjectBinding var driver: Driver<Msg, Model>
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20.0) {
                Spacer()
                
                HStack {
                    stepper.frame(width: 200.0, alignment: .center)
                }
                
                Spacer()
                
                NavigationLink(destination:
                    dependsOn(\.self, self.driver, historyView(driver:))
                ) { Text("History") }

                Spacer()

                TextField("URL", text: driver.binding(\.url, Msg.setURL))
                    .textContentType(.URL)
                    .frame(width: 300.0, alignment: .center)
                    .foregroundColor(.white)
                    .background(Color.gray.opacity(0.5))

                Button(action: {
                    self.driver.dispatch(.showWeb)
                }) {
                    Text("Show web")
                }.presentation(dependsOn(\.model.safariViewModel, self.driver, safariViewModal(driver:)))

                Group {
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                }
            }
        }
        .onDisappear {
            print("disappear")
        }
    }
    
    var stepper: some View {
        Stepper(onIncrement: {
            self.driver.dispatch(.step(.up))
        }, onDecrement: {
            self.driver.dispatch(.step(.down))
        }) {
            Text(String(self.driver.model.count))
        }
    }
    
    func historyView(driver: Driver<Msg, Model>) -> some View {
        HistoryView(driver: driver.derive(\Model.historyViewModel, Msg.historyViewMsg))
            .onAppear { self.driver.dispatch(.showHistory) }
    }
    
    func safariViewModal(driver: Driver<Msg, Model>) -> Modal? {
        guard let d = driver.derive(\.safariViewModel, Msg.safariViewMsg) else { return .none }
        return Modal(SafariView(driver: d).onDisappear(perform: {
            d.dispatch(.onDisappear)
        }))
    }
    
    static func == (lhs: ContentView, rhs: ContentView) -> Bool {
        if lhs.driver != rhs.driver { return false }
        return true
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(driver.model)
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(driver: Driver(model: .init(), dispatch: { _ in }))
    }
}
#endif
