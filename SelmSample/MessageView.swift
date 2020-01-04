//
//  MessageView.swift
//  Selm
//
//  Created by 和泉田 領一 on 2019/12/20.
//
//

import SwiftUI
import Combine
import Selm

struct MessageView: UIViewControllerRepresentable {
    var store: Store<MessageViewController>

    func makeUIViewController(context: Context) -> MessageViewController {
        MessageViewController(store: store)
    }

    func updateUIViewController(_ uiViewController: MessageViewController, context: Context) {}
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(store: .init(model: .init(message: "message")))
    }
}
