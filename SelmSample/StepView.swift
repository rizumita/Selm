//
//  StepView.swift
//  Selm
//
//  Created by 和泉田 領一 on 2019/12/19.
//
//

import SwiftUI
import Selm

struct StepView: SelmView {
    @ObservedObject var store: Store<StepPage>
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var content: some View {
        VStack {
            Spacer()

            Text(self.model.step.string)

            Spacer()

            Button(action: {
                self.dispatch(.remove)
                self.presentationMode.wrappedValue.dismiss()
            }, label: { Text("Remove") })

            Spacer()
        }
    }
}

struct StepView_Previews: PreviewProvider {
    static var previews: some View {
        StepView(store: .init(model: .init(step: .up)))
    }
}
