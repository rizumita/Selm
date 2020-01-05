//
//  ContentView.swift
//  SelmSample
//
//  Created by 和泉田 領一 on 2019/07/01.
//

import SwiftUI
import Combine
import Selm

struct ContentView: View {
    @ObservedObject var store: Store<Msg, Model>
    
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
                    NavigationLink(destination: HistoryView(store: store.derived(Msg.historyViewMsg, \.historyViewModel))) {
                        Text("Show history")
                    }
                    
                    Button(action: {
                        self.store.dispatch(.showSafariView)
                    }) {
                        Text("Show Safari sheet")
                    }.sheet(item: store.derivedBinding(Msg.safariViewMsg, \.safariViewModel)) { safariStore in
                        SafariView(store: safariStore)
                    }

                    Button(action: {
                        self.dispatch(.showMessageView)
                    }, label: { Text("Show message sheet") })
                    .sheet(item: store.derivedBinding(Msg.messageViewMsg, \.messageViewModel),
                           content: MessageView.init(store:))
                }

                Spacer()
            }.selmish(self)
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(store: Store(model: .init(historyViewModel: .init())))
    }
}
#endif
