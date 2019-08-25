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

struct ContentView : View, SelmView {
    typealias Page = ContentPage
    
    @ObservedObject var driver: Driver<Msg, Model>
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20.0) {
                Spacer()
                
                HStack {
                    stepper.frame(width: 200.0, alignment: .center)
                }
                
                Spacer()
                
                NavigationLink(destination: HistoryView(driver: driver.derived(Msg.historyPageMsg, \.historyPageModel))) {
                    Text("Show history")
                }

                Spacer()

                TextField("URL", text: driver.binding(Msg.setURL, \.url))
                    .textContentType(.URL)
                    .frame(width: 300.0, alignment: .center)
                    .foregroundColor(.white)
                    .background(Color.gray.opacity(0.5))

                Button(action: {
                    self.driver.dispatch(.showWeb)
                }) {
                    Text("Show web")
                }.sheet(item: driver.derivedBinding(Msg.safariPageMsg, \Model.safariPageModel), onDismiss: {
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
        HistoryView(driver: driver.derived(Msg.historyPageMsg, \Model.historyPageModel))
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(driver: Driver(model: .init(historyPageModel: .init(history: [])), dispatch: { _ in }))
    }
}
#endif
