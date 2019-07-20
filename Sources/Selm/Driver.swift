//
//  Driver.swift
//  Selm
//
//  Created by 和泉田 領一 on 2019/07/07.
//

import Foundation
import SwiftUI
import Combine

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public class Driver<Msg, Model>: BindableObject {
    public var willChange = PassthroughSubject<Model, Never>()
    
    public private(set) var model: Model {
        willSet {
            willChange.send(newValue)
        }
    }
    public var dispatch: Dispatch<Msg>
    
    private var isSubscribing: Bool = false
    
    public init(model: Model, dispatch: @escaping Dispatch<Msg>) {
        self.model = model
        self.dispatch = dispatch
        
        subscribe()
    }
    
    public func subscribe() {
        isSubscribing = true
    }
    
    public func unsubscribe() {
        isSubscribing = false
    }
    
    public func derived<SubMsg, SubModel>(_ keyPath: KeyPath<Model, SubModel>,
                                          _ messaging: @escaping (SubMsg) -> Msg) -> Driver<SubMsg, SubModel> {
        return Driver<SubMsg, SubModel>(model: model[keyPath: keyPath], dispatch: { self.dispatch(messaging($0)) })
    }
    
    public func derived<SubMsg, SubModel>(_ keyPath: KeyPath<Model, SubModel?>,
                                          _ messaging: @escaping (SubMsg) -> Msg) -> Driver<SubMsg, SubModel>? {
        guard let m = model[keyPath: keyPath] else { return .none }
        return Driver<SubMsg, SubModel>(model: m, dispatch: { self.dispatch(messaging($0)) })
    }
    
    public func derivedBinding<SubMsg, SubModel>(_ keyPath: KeyPath<Model, SubModel?>,
                                                 _ messaging: @escaping (SubMsg) -> Msg) -> Binding<Driver<SubMsg, SubModel>?> {
        Binding(getValue: { [weak self] in
            self?.derived(keyPath, messaging)
            },
                setValue: { value in
        })
    }
    
    public func binding<Value>(_ keyPath: KeyPath<Model, Value>, _ messaging: @escaping (Value) -> Msg) -> Binding<Value> {
        Binding(getValue: { [weak self] in
            guard let this = self else { fatalError() }
            return this.model[keyPath: keyPath]
            },
                setValue: { [weak self] value in
                    self?.dispatch(messaging(value))
        })
    }
    
    func update(_ model: Model) {
        self.model = model
    }
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Driver: Equatable where Model: Equatable {
    public static func ==(lhs: Driver<Msg, Model>, rhs: Driver<Msg, Model>) -> Bool {
        if lhs.model != rhs.model { return false }
        return true
    }
}
