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

struct ContentView: SelmView {
    @ObservedObject var store: Store<ContentPage>
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20.0) {
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
                    self.dispatch(.stepDelayed(.up))
                }) {
                    Text("Up with delay")
                }
                
                Button(action: {
                    self.dispatch(.stepDelayedTask(.up))
                }) {
                    Text("Up with delay task")
                }
                
                Button(action: {
                    self.dispatch(.stepTimer(.up))
                }) {
                    Text("Up with timer combine")
                }
                
                Button(action: {
                    self.dispatch(.stepTimerTwice(.up))
                }) {
                    Text("Up twice with timer combine")
                }

                Spacer()

                Group {
                    NavigationLink(destination: HistoryView(store: store.derived(Msg.historyPageMsg, \.historyPageModel))) {
                        Text("Show history")
                    }
                    
                    Button(action: {
                        self.store.dispatch(.showSafariPage)
                    }) {
                        Text("Show Safari sheet")
                    }
                    .sheet(item: store.derivedBinding(Msg.safariPageMsg, \.safariPageModel)) { substore in
                        SafariView(store: substore)
                    }
                }

                Spacer()
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(store: Store(model: .init(historyPageModel: .init(history: []))))
    }
}
#endif
