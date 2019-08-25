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

struct SafariView : UIViewControllerRepresentable, SelmView {
    typealias Page = SafariPage

    @ObservedObject var driver: Driver<Msg, Model>

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        SFSafariViewController(url: driver.model.url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {}
}

#if DEBUG
struct WebView_Previews : PreviewProvider {
    static var previews: some View {
        SafariView(driver: .init(model: .init(url: URL(string: "https://example.com")!), dispatch: { _ in }))
    }
}
#endif
