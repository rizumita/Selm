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
                
                Spacer()
                
                NavigationLink(destination: HistoryView(store: store.derived(Msg.historyPageMsg, \.historyPageModel))) {
                    Text("Show history")
                }

                Spacer()
            }
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
