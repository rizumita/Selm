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

struct HistoryView : View, SelmView {
    @ObservedObject var store: Store<HistoryPage>
    
    var body: some View {
        VStack(spacing: 20.0) {
            List {
                ForEach(model.history, id: \.self) { step in
                    Text(step.string)
                }.onDelete(perform: dispatch • Msg.remove)
            }
        }
    }
}

#if DEBUG
struct HistoryView_Previews : PreviewProvider {
    static var previews: some View {
        HistoryView(store: .init(model: .init(history: []), dispatch: { _ in }))
    }
}
#endif
