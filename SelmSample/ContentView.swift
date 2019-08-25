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
    @ObservedObject var store: Store<ContentPage>
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20.0) {
                Spacer()
                
                HStack {
                    stepper.frame(width: 200.0, alignment: .center)
                }
                
                Spacer()
                
                NavigationLink(destination: HistoryView(store: store.derived(Msg.historyPageMsg, \.historyPageModel))) {
                    Text("Show history")
                }

                Spacer()

                TextField("URL", text: store.binding(Msg.setURL, \.url))
                    .textContentType(.URL)
                    .frame(width: 300.0, alignment: .center)
                    .foregroundColor(.white)
                    .background(Color.gray.opacity(0.5))

                Button(action: {
                    self.store.dispatch(.showWeb)
                }) {
                    Text("Show web")
                }.sheet(item: store.derivedBinding(Msg.safariPageMsg, \Model.safariPageModel), onDismiss: {
                    self.store.dispatch(.hideWeb)
                }, content: SafariView.init(store:))

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
            self.store.dispatch(.step(.up))
        }, onDecrement: {
            self.store.dispatch(.step(.down))
        }) {
            Text(String(self.store.model.count))
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(store: Store(model: .init(historyPageModel: .init(history: [])), dispatch: { _ in }))
    }
}
#endif
