//
//  Driver.swift
//  Selm
//
//  Created by 和泉田 領一 on 2019/07/07.
//

import Foundation
import SwiftUI
#if canImport(Combine)
    import Combine
#endif

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public class Driver<Msg, Model>: ObservableObject, Identifiable {
    public var willChange = PassthroughSubject<Model, Never>()
    public let id = UUID()
    
    @Published public private(set) var model: Model {
        willSet {
            if isSubscribing {
                willChange.send(newValue)
            }
        }
    }
    public var dispatch: Dispatch<Msg>
    
    private var isSubscribing: Bool = false
    private var cancellables = Set<AnyCancellable>()
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
        isSubscribing = true
    }
    
    public func unsubscribe() {
        isSubscribing = false
    }

    public func derived<SubMsg, SubModel>(_ messaging: @escaping (SubMsg) -> Msg,
                                          _ keyPath: KeyPath<Model, SubModel>) -> Driver<SubMsg, SubModel> where SubModel: Equatable {
        let result = Driver<SubMsg, SubModel>(model: model[keyPath: keyPath], dispatch: { self.dispatch(messaging($0)) })
        $model.share().map(keyPath).removeDuplicates().sink { [weak result] model in
            result?.model = model
        }.store(in: &cancellables)

        return result
    }

    public func derived<SubMsg, SubModel>(_ messaging: @escaping (SubMsg) -> Msg,
                                          _ keyPath: KeyPath<Model, SubModel>) -> Driver<SubMsg, SubModel> {
        let result = Driver<SubMsg, SubModel>(model: model[keyPath: keyPath], dispatch: { self.dispatch(messaging($0)) })
        $model.share().map(keyPath).sink { [weak result] model in
            result?.model = model
        }.store(in: &cancellables)

        return result
    }

    public func derived<SubMsg, SubModel>(_ messaging: @escaping (SubMsg) -> Msg,
                                          _ keyPath: KeyPath<Model, SubModel?>) -> Driver<SubMsg, SubModel>? where SubModel: Equatable {
        guard let m = model[keyPath: keyPath] else { return .none }
        let result = Driver<SubMsg, SubModel>(model: m, dispatch: { self.dispatch(messaging($0)) })
        
        $model.share().map(keyPath).removeDuplicates().sink { [weak result] model in
            guard let model = model else { return }
            result?.model = model
        }.store(in: &cancellables)
        
        return result
    }

    public func derived<SubMsg, SubModel>(_ messaging: @escaping (SubMsg) -> Msg,
                                          _ keyPath: KeyPath<Model, SubModel?>) -> Driver<SubMsg, SubModel>? {
        guard let m = model[keyPath: keyPath] else { return .none }
        let result = Driver<SubMsg, SubModel>(model: m, dispatch: { self.dispatch(messaging($0)) })
        
        $model.share().map(keyPath).sink { [weak result] model in
            guard let model = model else { return }
            result?.model = model
        }.store(in: &cancellables)
        
        return result
    }
    
    public func derivedBinding<SubMsg, SubModel>(_ messaging: @escaping (SubMsg) -> Msg,
                                                 _ keyPath: KeyPath<Model, SubModel?>) -> Binding<Driver<SubMsg, SubModel>?> {
        Binding(get: { [weak self] in
            self?.derived(messaging, keyPath)
            },
                set: { value in
        })
    }
    
    public func binding<Value>(_ messaging: @escaping (Value) -> Msg,
                               _ keyPath: KeyPath<Model, Value>) -> Binding<Value> {
        Binding(get: { [weak self] in
            guard let this = self else { fatalError() }
            return this.model[keyPath: keyPath]
            },
                set: { [weak self] value in
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
