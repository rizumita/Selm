//
// Created by 和泉田 領一 on 2019/12/20.
//

import Foundation
import SwiftUI

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol SelmView: View {
    associatedtype Page: _SelmPage
    associatedtype Msg = Page.Msg
    associatedtype Model = Page.Model
    associatedtype ViewType: View

    var store: Store<Page> { get }

    var content: ViewType { get }
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension SelmView {

    public var content: some View {
        // I did this to prevent changing every view right now
        // In the final implementation, this would be a requiement of conforming to SelmView
        return Text("Hello, world")
    }

    public var body: some View {
        content
            .onAppear {
                if Page.subscribesOnAppear {
                    self.store.subscribe()
                }

                if let onAppearMsg = Page.onAppearMsg {
                    self.store.dispatch(onAppearMsg)
                }
            }
            .onDisappear {
                if Page.unsubscribesOnDisappear {
                    self.store.unsubscribe()
                }

                if let onDisappearMsg = Page.onDisappearMsg {
                    self.store.dispatch(onDisappearMsg)
                }
            }
    }

}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension SelmView {
    public var model:    Page.Model { store.model }
    public var dispatch: Dispatch<Page.Msg> { store.dispatch }
}
