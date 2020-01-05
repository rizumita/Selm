//
//  SafariView.swift
//  SelmSample
//
//  Created by 和泉田 領一 on 2019/07/01.
//

import SwiftUI
import SafariServices
import Combine
import Selm

struct SafariView: View {
    let store: Store<Msg, Model>
    
    var body: some View {
        _SafariView(url: store.model.url).selmish(self)
    }
}

struct _SafariView : UIViewControllerRepresentable {
    var url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<_SafariView>) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<_SafariView>) {}
}

#if DEBUG
struct WebView_Previews : PreviewProvider {
    static var previews: some View {
        SafariView(store: .init(model: .init(url: URL(string: "https://example.com")!)))
    }
}
#endif
