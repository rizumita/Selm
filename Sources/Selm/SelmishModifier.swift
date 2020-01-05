//
// Created by 和泉田 領一 on 2020/01/05.
//

import SwiftUI

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct SelmishModifier: ViewModifier {
    private let onAppear:    () -> ()
    private let onDisappear: () -> ()

    public init<V: _SelmView>(_ selmView: V) {
        self.onAppear = {
            if V.subscribesOnAppear {
                selmView.store.subscribe()
            }

            if let onAppearMsg = V.onAppearMsg {
                selmView.store.dispatch(onAppearMsg)
            }
        }

        self.onDisappear = {
            if V.unsubscribesOnDisappear {
                selmView.store.unsubscribe()
            }

            if let onDisappearMsg = V.onDisappearMsg {
                selmView.store.dispatch(onDisappearMsg)
            }
        }
    }

    public func body(content: Content) -> some View {
        content.onAppear(perform: onAppear)
               .onDisappear(perform: onDisappear)
    }
}

extension View {
    public func selmish<V: _SelmView>(_ selmView: V) -> some View {
        modifier(SelmishModifier(selmView))
    }
}
