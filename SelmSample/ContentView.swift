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

struct ContentView : View {
    struct Model: Equatable {
        var count: Int = 0
        var url: String = ""
        var historyViewModel: HistoryView.Model
        var safariViewModel: SafariView.Model?
        
        static func == (lhs: Model, rhs: Model) -> Bool {
            if lhs.count != rhs.count { return false }
            return true
        }
    }
    
    enum Msg {
        case historyViewMsg(HistoryView.Msg)
        case safariViewMsg(SafariView.Msg)
        case step(Step)
        case setURL(String)
        case showWeb
        case hideWeb
    }
    
    static func initialize() -> (Model, Cmd<Msg>) {
        let (m, c) = HistoryView.initialize(history: [])
        return (Model(historyViewModel: m), c.map(Msg.historyViewMsg))
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
            return (model |> set(\.count, step.step(count: model.count)),
                    .ofMsg(.historyViewMsg(.add(step))))
            
        case .setURL(let urlString):
            return (model |> set(\.url, urlString), .none)
            
        case .showWeb:
            guard let url = URL(string: model.url) else { return (model, .none) }
            let (m, c) = SafariView.initialize(url: url)
            return (model |> set(\.safariViewModel, m), c.map(Msg.safariViewMsg))
            
        case .hideWeb:
            return (model |> set(\.safariViewModel, .none), .none)
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
                
                NavigationLink(destination: dependsOn(\.model.historyViewModel, self.driver, historyView(driver:))) {
                    Text("Show history")
                }

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
                }.sheet(item: driver.derivedBinding(\.safariViewModel, Msg.safariViewMsg), onDismiss: {
                    self.driver.dispatch(.hideWeb)
                }, content: SafariView.init(driver:))

                Group {
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                }
            }
            .onDisappear {
                print("disappear")
            }

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
        HistoryView(driver: driver.derived(\Model.historyViewModel, Msg.historyViewMsg))
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(driver: Driver(model: .init(historyViewModel: .init(history: [])), dispatch: { _ in }))
    }
}
#endif
