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
public final class Store<Msg, Model>: ObservableObject, Identifiable {
    public let id = UUID()
    public let objectWillChange: AnyPublisher<Model, Never>

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

    private let willChange          = PassthroughSubject<Model, Never>()
    private let releasedSubject     = PassthroughSubject<(), Never>()
    private var isSubscribing: Bool = true
    private var storeStorage        = StoreStorage<Model>()
    private var identifiedBindings  = [AnyHashable: Any]()
    private var cancellables        = Set<AnyCancellable>()

    public init(model: Model, dispatch: @escaping Dispatch<Msg> = { _ in }) {
        self.model = model
        self.dispatch = dispatch
        self.objectWillChange = willChange.eraseToAnyPublisher()
    }

    init(model: Model, dispatch: @escaping Dispatch<Msg> = { _ in }, equals: @escaping (Model, Model) -> Bool) {
        self.model = model
        self.dispatch = dispatch
        self.objectWillChange = willChange.removeDuplicates(by: equals).eraseToAnyPublisher()
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

    public func derived<SubMsg, SubModel>(_ messaging: @escaping (SubMsg) -> Msg,
                                          _ keyPath: KeyPath<Model, SubModel>,
                                          isTemporary: Bool = false) -> Store<SubMsg, SubModel> {
        if !isTemporary, let derivedStore = storeStorage.load(forKeyPath: keyPath) as? Store<SubMsg, SubModel> {
            derivedStore.model = model[keyPath: keyPath]
            return derivedStore
        }

        let result = Store<SubMsg, SubModel>(model: model[keyPath: keyPath], dispatch: { self.dispatch(messaging($0)) })
        $model.share().map(keyPath).sink { [weak result] model in
            result?.model = model
        }.store(in: &cancellables)

        if !isTemporary {
            storeStorage.save(result, forKeyPath: keyPath)
        }

        return result
    }

    public func derived<SubMsg, SubModel>(_ messaging: @escaping (SubMsg) -> Msg,
                                          _ keyPath: KeyPath<Model, SubModel>,
                                          isTemporary: Bool = false) -> Store<SubMsg, SubModel> where SubModel: Equatable {
        if !isTemporary, let derivedStore = storeStorage.load(forKeyPath: keyPath) as? Store<SubMsg, SubModel> {
            derivedStore.model = model[keyPath: keyPath]
            return derivedStore
        }

        let result = Store<SubMsg, SubModel>(model: model[keyPath: keyPath],
                                             dispatch: { self.dispatch(messaging($0)) },
                                             equals: ==)
        $model.share().map(keyPath).sink { [weak result] model in
            result?.model = model
        }.store(in: &cancellables)

        if !isTemporary {
            storeStorage.save(result, forKeyPath: keyPath)
        }

        return result
    }

    public func derived<SubMsg, SubModel>(_ messaging: @escaping (SubMsg) -> Msg,
                                          _ keyPath: KeyPath<Model, SubModel?>,
                                          isTemporary: Bool = false) -> Store<SubMsg, SubModel>? {
        guard let m = model[keyPath: keyPath] else { return .none }
        if !isTemporary, let derivedStore = storeStorage.load(forKeyPath: keyPath) as? Store<SubMsg, SubModel> {
            derivedStore.model = m
            return derivedStore
        }

        let result = Store<SubMsg, SubModel>(model: m, dispatch: { self.dispatch(messaging($0)) })

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

        if !isTemporary {
            storeStorage.save(result, forKeyPath: keyPath)
        }

        return result
    }

    public func derived<SubMsg, SubModel>(_ messaging: @escaping (SubMsg) -> Msg,
                                          _ keyPath: KeyPath<Model, SubModel?>,
                                          isTemporary: Bool = false) -> Store<SubMsg, SubModel>? where SubModel: Equatable {
        guard let m = model[keyPath: keyPath] else { return .none }
        if !isTemporary, let derivedStore = storeStorage.load(forKeyPath: keyPath) as? Store<SubMsg, SubModel> {
            derivedStore.model = m
            return derivedStore
        }

        let result = Store<SubMsg, SubModel>(model: m, dispatch: { self.dispatch(messaging($0)) }, equals: ==)

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

        if !isTemporary {
            storeStorage.save(result, forKeyPath: keyPath)
        }

        return result
    }

    public func derived<SubMsg, SubModel>(_ id: SubModel.ID,
                                          _ messaging: @escaping (SubMsg) -> Msg,
                                          _ keyPath: KeyPath<Model, [SubModel]>,
                                          isTemporary: Bool = false) -> Store<SubMsg, SubModel>
        where SubModel: Identifiable {
        guard let derivedModel = model[keyPath: keyPath][id: id] else { fatalError("Invalid ID") }

        if !isTemporary, let store = storeStorage.load(forID: id) as? Store<SubMsg, SubModel> {
            store.model = derivedModel
            return store
        }

        let result = Store<SubMsg, SubModel>(model: derivedModel, dispatch: { self.dispatch(messaging($0)) })

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

        if !isTemporary {
            storeStorage.save(result, forID: id)
        }

        return result
    }

    public func derived<SubMsg, SubModel>(_ id: SubModel.ID,
                                          _ messaging: @escaping (SubMsg) -> Msg,
                                          _ keyPath: KeyPath<Model, [SubModel]>,
                                          isTemporary: Bool = false) -> Store<SubMsg, SubModel>
        where SubModel: Identifiable, SubModel: Equatable {
        guard let derivedModel = model[keyPath: keyPath][id: id] else { fatalError("Invalid ID") }

        if !isTemporary, let store = storeStorage.load(forID: id) as? Store<SubMsg, SubModel> {
            store.model = derivedModel
            return store
        }

        let result = Store<SubMsg, SubModel>(model: derivedModel,
                                             dispatch: { self.dispatch(messaging($0)) },
                                             equals: ==)

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

        if !isTemporary {
            storeStorage.save(result, forID: id)
        }

        return result
    }

    public func derivedBinding<SubMsg, SubModel>(_ messaging: @escaping (SubMsg) -> Msg,
                                                 _ keyPath: KeyPath<Model, SubModel?>,
                                                 isTemporary: Bool = false) -> Binding<Store<SubMsg, SubModel>?> {
        Binding(get: { [weak self] in
            self?.derived(messaging, keyPath, isTemporary: isTemporary)
        }, set: { value in })
    }

    public func derivedBinding<SubMsg, SubModel>(_ messaging: @escaping (SubMsg) -> Msg,
                                                 _ keyPath: KeyPath<Model, SubModel?>,
                                                 isTemporary: Bool = false) -> Binding<Store<SubMsg, SubModel>?> where SubModel: Equatable {
        Binding(get: { [weak self] in
            self?.derived(messaging, keyPath, isTemporary: isTemporary)
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

    public func binding(_ messaging: @escaping (Model) -> Msg) -> Binding<Model> {
        Binding(get: { [unowned self] in self.model },
                set: { [unowned self] value in self.dispatch(messaging(value)) })
    }

    public subscript<SubModel>(dynamicMember keyPath: WritableKeyPath<Model, SubModel>) -> Store<Msg, SubModel> {
        let result = Store<Msg, SubModel>(model: model[keyPath: keyPath], dispatch: dispatch)

        objectWillChange.share().map(keyPath).sink { [weak result] model in
            result?.model = model
        }.store(in: &cancellables)

        return result
    }

    func update(_ model: Model) {
        self.model = model
    }
}
