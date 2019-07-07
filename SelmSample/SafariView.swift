//
//  SafariView.swift
//  SelmSample
//
//  Created by 和泉田 領一 on 2019/07/01.
//

import SwiftUI
import SafariServices
import Combine
import Swiftx
import Operadics
import Selm

struct SafariPage {
    class Model: BindableObject {
        var didChange = PassthroughSubject<(), Never>()
        var url: URL
        
        init(url: URL) {
            self.url = url
        }
    }
    
    enum Msg {
        case onDisappear
    }
    
    enum ExternalMsg {
        case noOp
        case dismiss
    }
    
    static func initialize(url: URL) -> (Model, Cmd<Msg>) {
        (Model(url: url), .none)
    }
    
    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>, ExternalMsg) {
        switch msg {
        case .onDisappear:
            return (model, .none, .dismiss)
        }
    }
}

struct SafariView : UIViewControllerRepresentable {
    @ObjectBinding var model: SafariPage.Model
    var dispatch: Dispatch<SafariPage.Msg>

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        SFSafariViewController(url: model.url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {}
}

#if DEBUG
struct WebView_Previews : PreviewProvider {
    static var previews: some View {
        SafariView(model: .init(url: URL(string: "http://example.com")!), dispatch: { _ in })
    }
}
#endif
