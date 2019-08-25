//
//  Store.swift
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
public class Store<Page>: ObservableObject, Identifiable where Page: _SelmPage {
    public typealias Msg = Page.Msg
    public typealias Model = Page.Model
    
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

    public func derived<SubPage, SubModel>(_ messaging: @escaping (SubPage.Msg) -> Msg,
                                 _ keyPath: KeyPath<Model, SubModel>) -> Store<SubPage> where SubPage.Model == SubModel, SubModel: Equatable {
        let result = Store<SubPage>(model: model[keyPath: keyPath], dispatch: { self.dispatch(messaging($0)) })
        $model.share().map(keyPath).removeDuplicates().sink { [weak result] model in
            result?.model = model
        }.store(in: &cancellables)

        return result
    }

    public func derived<SubPage>(_ messaging: @escaping (SubPage.Msg) -> Msg,
                                 _ keyPath: KeyPath<Model, SubPage.Model>) -> Store<SubPage> {
        let result = Store<SubPage>(model: model[keyPath: keyPath], dispatch: { self.dispatch(messaging($0)) })
        $model.share().map(keyPath).sink { [weak result] model in
            result?.model = model
        }.store(in: &cancellables)

        return result
    }

    public func derived<SubPage, SubModel>(_ messaging: @escaping (SubPage.Msg) -> Msg,
                                 _ keyPath: KeyPath<Model, SubModel?>) -> Store<SubPage>? where SubPage.Model == SubModel, SubModel: Equatable {
        guard let m = model[keyPath: keyPath] else { return .none }
        let result = Store<SubPage>(model: m, dispatch: { self.dispatch(messaging($0)) })
        
        $model.share().map(keyPath).removeDuplicates().sink { [weak result] model in
            guard let model = model else { return }
            result?.model = model
        }.store(in: &cancellables)
        
        return result
    }

    public func derived<SubPage>(_ messaging: @escaping (SubPage.Msg) -> Msg,
                                 _ keyPath: KeyPath<Model, SubPage.Model?>) -> Store<SubPage>? {
        guard let m = model[keyPath: keyPath] else { return .none }
        let result = Store<SubPage>(model: m, dispatch: { self.dispatch(messaging($0)) })
        
        $model.share().map(keyPath).sink { [weak result] model in
            guard let model = model else { return }
            result?.model = model
        }.store(in: &cancellables)
        
        return result
    }
    
    public func derivedBinding<SubPage>(_ messaging: @escaping (SubPage.Msg) -> Msg,
                                        _ keyPath: KeyPath<Model, SubPage.Model?>) -> Binding<Store<SubPage>?> {
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
extension Store: Equatable where Page.Model: Equatable {
    public static func ==(lhs: Store<Page>, rhs: Store<Page>) -> Bool {
        if lhs.model != rhs.model { return false }
        return true
    }
}
