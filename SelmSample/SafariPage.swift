//
//  SafariPage.swift
//  SelmSample
//
//  Created by 和泉田 領一 on 2019/08/24.
//

import Foundation
import Combine
import Swiftx
import Operadics
import Selm

struct SafariPage: SelmPageExt {
    struct Model: Equatable {
        var url: URL
        
        static func ==(lhs: Model, rhs: Model) -> Bool {
            if lhs.url != rhs.url { return false }
            return true
        }
    }
    
    enum Msg {
        case dismiss
    }

    private(set) static var onDisappearMsg: Msg? = .dismiss

    enum ExternalMsg {
        case noOp
        case dismiss
    }
    
    static func initialize(url: URL) -> (Model, Cmd<Msg>) {
        (Model(url: url), .none)
    }
    
    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>, ExternalMsg) {
        switch msg {
        case .dismiss:
            return (model, .none, .dismiss)
        }
    }
}
