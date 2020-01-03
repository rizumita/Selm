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
public final class Store<Page>: ObservableObject, Identifiable where Page: _SelmPage {
    public typealias Msg = Page.Msg
    public typealias Model = Page.Model

    public let id = UUID()
    public private(set) lazy var objectWillChange: AnyPublisher<Model, Never>
        = willChange.removeDuplicates(by: Model.equals).eraseToAnyPublisher()

    @Published public private(set) var model: Model {
        willSet {
            if isSubscribing {
                willChange.send(newValue)
            }
        }
    }
    public let dispatch: Dispatch<Msg>

    public var released: AnyPublisher<(), Never> {
        releasedSubject.eraseToAnyPublisher()
    }

    private let willChange              = PassthroughSubject<Model, Never>()
    private let releasedSubject         = PassthroughSubject<(), Never>()
    private var isSubscribing: Bool     = false
    private var storeStorage            = StoreStorage<Page.Model>()
    private var identifiedBindings = [AnyHashable: Any]()
    private var cancellables            = Set<AnyCancellable>()

    public init(model: Model, dispatch: @escaping Dispatch<Msg> = { _ in }) {
        self.model = model
        self.dispatch = dispatch
        self.isSubscribing = true
    }

    public func subscribe() {
        guard !isSubscribing else { return }

        run(on: .main) {
            self.isSubscribing = true
            self.willChange.send(self.model)
        }
    }

    public func unsubscribe() {
        guard isSubscribing else { return }

        run(on: .main) {
            self.isSubscribing = false
        }
    }

    public func derived<SubPage: _SelmPage>(_ messaging: @escaping (SubPage.Msg) -> Msg,
                                            _ keyPath: KeyPath<Model, SubPage.Model>,
                                            isTemporary: Bool = false,
                                            isSubscribing: Bool = SubPage.unsubscribesOnDisappear) -> Store<SubPage> {
        if !isTemporary, let derivedStore = storeStorage.load(forKeyPath: keyPath) as? Store<SubPage> {
            derivedStore.model = model[keyPath: keyPath]
            return derivedStore
        }

        let result = Store<SubPage>(model: model[keyPath: keyPath], dispatch: { self.dispatch(messaging($0)) })
        $model.share().map(keyPath).sink { [weak result] model in
            result?.model = model
        }.store(in: &cancellables)

        result.isSubscribing = isSubscribing

        if !isTemporary {
            storeStorage.save(result, forKeyPath: keyPath)
        }

        return result
    }

    public func derived<SubPage: _SelmPage>(_ messaging: @escaping (SubPage.Msg) -> Msg,
                                            _ keyPath: KeyPath<Model, SubPage.Model?>,
                                            isTemporary: Bool = false,
                                            isSubscribing: Bool = SubPage.unsubscribesOnDisappear) -> Store<SubPage>? {
        guard let m = model[keyPath: keyPath] else { return .none }
        if !isTemporary, let derivedStore = storeStorage.load(forKeyPath: keyPath) as? Store<SubPage> {
            derivedStore.model = m
            return derivedStore
        }

        let result = Store<SubPage>(model: m, dispatch: { self.dispatch(messaging($0)) })

        $model.share().map(keyPath).sink { [weak self, weak result] model in
            guard let model = model else {
                if !isTemporary {
                    self?.storeStorage.remove(forKeyPath: keyPath)
                }
                result?.releasedSubject.send(())
                return
            }
            result?.model = model
        }.store(in: &cancellables)

        result.isSubscribing = isSubscribing

        if !isTemporary {
            storeStorage.save(result, forKeyPath: keyPath)
        }

        return result
    }

    public func derived<SubPage: _SelmPage>(_ id: SubPage.Model.ID,
                                            _ messaging: @escaping (SubPage.Msg) -> Msg,
                                            _ keyPath: KeyPath<Model, [SubPage.Model]>,
                                            isTemporary: Bool = false,
                                            isSubscribing: Bool = SubPage.unsubscribesOnDisappear) -> Store<SubPage>
        where SubPage.Model: Identifiable {
        guard let derivedModel = model[keyPath: keyPath][id: id] else { fatalError("Invalid ID") }

        if !isTemporary, let store = storeStorage.load(forID: id) as? Store<SubPage> {
            store.model = derivedModel
            return store
        }

        let result = Store<SubPage>(model: derivedModel, dispatch: { self.dispatch(messaging($0)) })

        $model.share().map(keyPath).sink { [weak self, weak result] models in
            guard let model = models[id: id] else {
                if !isTemporary {
                    self?.storeStorage.remove(forID: id)
                }
                result?.releasedSubject.send(())
                return
            }
            result?.model = model
        }.store(in: &cancellables)

        result.isSubscribing = isSubscribing

        if !isTemporary {
            storeStorage.save(result, forID: id)
        }

        return result
    }

    public func derivedBinding<SubPage>(_ messaging: @escaping (SubPage.Msg) -> Msg,
                                        _ keyPath: KeyPath<Model, SubPage.Model?>,
                                        isTemporary: Bool = false,
                                        isSubscribing: Bool = true) -> Binding<Store<SubPage>?> {
        Binding(get: { [weak self] in
            self?.derived(messaging, keyPath, isTemporary: isTemporary, isSubscribing: isSubscribing)
        }, set: { value in })
    }

    public func binding<Value>(_ messaging: @escaping (Value) -> Msg,
                               _ keyPath: KeyPath<Model, Value>) -> Binding<Value> {
        Binding(get: { [weak self] in
            guard let this = self else { fatalError() }
            return this.model[keyPath: keyPath]
        }, set: { [weak self] value in self?.dispatch(messaging(value)) })
    }

    public func binding<Value>(_ value: Value,
                               _ messaging: @escaping (Value?) -> Msg,
                               _ keyPath: KeyPath<Model, Value?>) -> Binding<Value?> where Value: Equatable {
        Binding(get: { [weak self] in
            self?.model[keyPath: keyPath]
        }, set: { [weak self] newValue in
            if let newValue = newValue {
                self?.dispatch(messaging(newValue))
            } else {
                if let current = self?.model[keyPath: keyPath],
                   current == value {
                    self?.dispatch(messaging(newValue))
                }
            }
        })
    }

    public func binding<ID: Hashable, Value>(id: ID, type: Value.Type = Value.self) -> Binding<Value?> {
        Binding(get: { [weak self] in
            self?.identifiedBindings[id] as? Value
        }, set: { [weak self] value in
            guard let `self` = self else { return }
            self.identifiedBindings[id] = value
            self.willChange.send(self.model)
        })
    }

    func update(_ model: Model) {
        self.model = model
    }
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Store: Equatable where Model: Equatable {
    public static func ==(lhs: Store<Page>, rhs: Store<Page>) -> Bool {
        if lhs.model != rhs.model { return false }
        return true
    }
}
