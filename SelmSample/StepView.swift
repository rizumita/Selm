//
//  StepView.swift
//  Selm
//
//  Created by 和泉田 領一 on 2019/12/19.
//
//

import SwiftUI
import Selm

struct StepView: View {
    @ObservedObject var store: Store<Msg, Model>
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        VStack {
            Spacer()

            Text(self.model.step.string)

            Spacer()

            Button(action: { self.dispatch(.toggle) }, label: { Text("Toggle") })

            Spacer()

            Button(action: {
                self.dispatch(.remove)
                self.presentationMode.wrappedValue.dismiss()
            }, label: { Text("Remove") })

            Spacer()
        }.selmish(self)
    }
}

struct StepView_Previews: PreviewProvider {
    static var previews: some View {
        StepView(store: .init(model: .init(step: .up)))
    }
}
