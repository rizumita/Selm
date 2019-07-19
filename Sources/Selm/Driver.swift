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

    private let modelSubject: CurrentValueSubject<Model, Never>
    public var model: Model {
        return modelSubject.value
    }
    public var dispatch: Dispatch<Msg>

    private var cancellable: AnyCancellable?
    private var deinitSubject = PassthroughSubject<(), Never>()
    
    public init(model: Model, dispatch: @escaping Dispatch<Msg>) {
        self.modelSubject = CurrentValueSubject<Model, Never>(model)
        self.dispatch = dispatch
        
        subscribe()
    }
    
    deinit {
        deinitSubject.send(())
    }
    
    public func subscribe() {
        unsubscribe()
        cancellable = modelSubject.share().receive(on: RunLoop.main).subscribe(on: RunLoop.main).subscribe(self.willChange)
    }
    
    public func unsubscribe() {
        cancellable?.cancel()
        cancellable = .none
    }
    
    public func derived<SubMsg, SubModel>(_ keyPath: KeyPath<Model, SubModel>,
                                         _ messaging: @escaping (SubMsg) -> Msg) -> Driver<SubMsg, SubModel> {
        let result = Driver<SubMsg, SubModel>(model: modelSubject.value[keyPath: keyPath], dispatch: { self.dispatch(messaging($0)) })
//        let sink = modelSubject.share().map(keyPath).sink { [weak result] model in
//            result?.modelSubject.send(model)
//        }
//        _ = result.deinitSubject.sink {
//            sink.cancel()
//        }
        return result
    }

    public func derived<SubMsg, SubModel>(_ keyPath: KeyPath<Model, SubModel?>,
                                          _ messaging: @escaping (SubMsg) -> Msg) -> Driver<SubMsg, SubModel>? {
        guard let m = modelSubject.value[keyPath: keyPath] else { return .none }
        let result = Driver<SubMsg, SubModel>(model: m, dispatch: { self.dispatch(messaging($0)) })
//        let sink = modelSubject.share().map(keyPath).sink { [weak result] model in
//            guard let model = model else { return }
//            result?.modelSubject.send(model)
//        }
//        _ = result.deinitSubject.sink {
//            sink.cancel()
//        }
        return result
    }
    
    public func derivedBinding<SubMsg, SubModel>(_ keyPath: KeyPath<Model, SubModel?>,
                                                 _ messaging: @escaping (SubMsg) -> Msg) -> Binding<Driver<SubMsg, SubModel>?> {
        Binding(getValue: { [weak self] in
            self?.derived(keyPath, messaging)
            },
                setValue: { _ in
                    print("derivedBinding.setValue")
        })
    }
    
    public func binding<Value>(_ keyPath: KeyPath<Model, Value>, _ messaging: @escaping (Value) -> Msg) -> Binding<Value> {
        Binding(getValue: { [weak self] in
            guard let this = self else { fatalError() }
            return this.modelSubject.value[keyPath: keyPath]
        },
                setValue: { [weak self] value in
                    self?.dispatch(messaging(value))
        })
    }
    
    func update(_ model: Model) {
        self.modelSubject.send(model)
    }
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Driver: Equatable where Model: Equatable {
    public static func ==(lhs: Driver<Msg, Model>, rhs: Driver<Msg, Model>) -> Bool {
        if lhs.modelSubject.value != rhs.modelSubject.value { return false }
        return true
    }
}
