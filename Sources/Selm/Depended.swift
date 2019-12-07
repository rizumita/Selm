//
//  Depended.swift
//  Selm
//
//  Created by 和泉田 領一 on 2019/12/07.
//

import Foundation

@propertyWrapper public enum Depended<D> {
    case empty
    case dependency(D)
    
    public init() {
        self = .empty
    }
    
    public var wrappedValue: D {
        get {
            switch self {
            case .empty:
                fatalError("\(type(of: self)) has to be set dependency.")
            case .dependency(let d):
                return d
            }
        }
        set {
            self = .dependency(newValue)
        }
    }
}
