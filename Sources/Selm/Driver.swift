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
    public var didChange = PassthroughSubject<Model, Never>()
    @Published public private(set) var model: Model
    public var dispatch: Dispatch<Msg>
    private var cancellable: AnyCancellable?
    private var deinitSubject = PassthroughSubject<(), Never>()
    
    public init(model: Model, dispatch: @escaping Dispatch<Msg>) {
        self.model = model
        self.dispatch = dispatch
        
        subscribe()
    }
    
    deinit {
        deinitSubject.send(())
    }
    
    public func subscribe() {
        unsubscribe()
        cancellable = $model.share().receive(on: RunLoop.main).subscribe(on: RunLoop.main).subscribe(self.didChange)
    }
    
    public func unsubscribe() {
        cancellable?.cancel()
        cancellable = .none
    }
    
    public func derive<SubMsg, SubModel>(_ keyPath: KeyPath<Model, SubModel>,
                                         _ messaging: @escaping (SubMsg) -> Msg) -> Driver<SubMsg, SubModel> {
        let result = Driver<SubMsg, SubModel>(model: model[keyPath: keyPath], dispatch: { self.dispatch(messaging($0)) })
        let sink = $model.share().sink { [weak result] model in
            result?.model = model[keyPath: keyPath]
        }
        _ = result.deinitSubject.sink {
            sink.cancel()
        }
        return result
    }

    public func derive<SubMsg, SubModel>(_ keyPath: KeyPath<Model, SubModel?>,
                                         _ messaging: @escaping (SubMsg) -> Msg) -> Driver<SubMsg, SubModel>? {
        guard let m = model[keyPath: keyPath] else { return .none }
        let result = Driver<SubMsg, SubModel>(model: m, dispatch: { self.dispatch(messaging($0)) })
        let sink = $model.share().sink { [weak result] model in
            guard let m = model[keyPath: keyPath] else { return }
            result?.model = m
        }
        _ = result.deinitSubject.sink {
            sink.cancel()
        }
        return result
    }
    
    public func binding<Value>(_ keyPath: KeyPath<Model, Value>, _ messaging: @escaping (Value) -> Msg) -> Binding<Value> {
        Binding(getValue: { [weak self] in
            guard let this = self else { fatalError() }
            return this.model[keyPath: keyPath]
        }) { [weak self] value in
            self?.dispatch(messaging(value))
        }
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
