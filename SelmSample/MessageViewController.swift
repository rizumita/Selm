//
// Created by 和泉田 領一 on 2019/12/20.
//

import UIKit
import Selm

final class MessageViewController: UIViewController {
    let store: Store<Msg, Model>
    var label  = UILabel()
    var button = UIButton(type: .roundedRect)

    init(store: Store<Msg, Model>) {
        self.store = store

        super.init(nibName: .none, bundle: .none)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()

        label.text = store.model.message
        button.setTitle("Dismiss", for: .normal)
        button.addTarget(self, action: #selector(handleDoing(_:)), for: .touchUpInside)

        view.addSubview(label)
        view.addSubview(button)

        label.frame = CGRect(x: 20.0, y: 50.0, width: 100.0, height: 44.0)
        button.sizeToFit()
        button.frame = CGRect(origin: CGPoint(x: 20.0, y: 100.0), size: button.frame.size)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        onAppear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        onDisappear(onDismiss: { dispatch(.dismiss) })
    }

    @objc func handleDoing(_ sender: Any) {
        dismiss(animated: true)
    }
}
