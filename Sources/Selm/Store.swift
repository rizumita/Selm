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

    private var willChange          = PassthroughSubject<Model, Never>()
    private var isSubscribing: Bool = false
    private var derivedStores       = [AnyKeyPath: Any]()
    private let derivedStoresQueue  = DispatchQueue(label: "Selm.Store.derivedStoresQueue")
    private var cancellables        = Set<AnyCancellable>()

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
                                            isSubscribing: Bool = SubPage.unsubscribesOnDisappear) -> Store<SubPage> {
        if let substore = derivedStores[keyPath] as? Store<SubPage> {
            return substore
        }

        let result = Store<SubPage>(model: model[keyPath: keyPath], dispatch: { self.dispatch(messaging($0)) })
        $model.share().map(keyPath).sink { [weak result] model in
            result?.model = model
        }.store(in: &cancellables)

        result.isSubscribing = isSubscribing

        addDerivedStore(result, for: keyPath)

        return result
    }

    public func derived<SubPage: _SelmPage>(_ messaging: @escaping (SubPage.Msg) -> Msg,
                                           _ keyPath: KeyPath<Model, SubPage.Model?>,
                                           isSubscribing: Bool = SubPage.unsubscribesOnDisappear) -> Store<SubPage>? {
        if let substore = derivedStores[keyPath] as? Store<SubPage> {
            return substore
        }

        guard let m = model[keyPath: keyPath] else { return .none }
        let result = Store<SubPage>(model: m, dispatch: { self.dispatch(messaging($0)) })

        $model.share().map(keyPath).sink { [weak self, weak result] model in
            guard let model = model else {
                self?.removeDerivedStore(for: keyPath)
                return
            }
            result?.model = model
        }.store(in: &cancellables)

        result.isSubscribing = isSubscribing

        addDerivedStore(result, for: keyPath)

        return result
    }

    public func derived<SubPage: _SelmPage>(_ model: SubPage.Model,
                                            _ messaging: @escaping (SubPage.Msg) -> Msg,
                                            _ keyPath: KeyPath<Model, [SubPage.Model]>,
                                            isSubscribing: Bool = SubPage.unsubscribesOnDisappear) -> Store<SubPage>
        where SubPage.Model: Identifiable {
        let result = Store<SubPage>(model: model, dispatch: { self.dispatch(messaging($0)) })
        $model.share().map(keyPath).sink { [weak result] models in
            guard let model = models.first(where: { $0.id == model.id }) else { return }
            result?.model = model
        }.store(in: &cancellables)

        result.isSubscribing = isSubscribing

        addDerivedStore(result, for: keyPath)

        return result
    }

    public func derivedBinding<SubPage>(_ messaging: @escaping (SubPage.Msg) -> Msg,
                                        _ keyPath: KeyPath<Model, SubPage.Model?>) -> Binding<Store<SubPage>?> {
        Binding(get: { [weak self] in self?.derived(messaging, keyPath) },
                set: { value in })
    }

    public func binding<Value>(_ messaging: @escaping (Value) -> Msg,
                               _ keyPath: KeyPath<Model, Value>) -> Binding<Value> {
        Binding(get: { [weak self] in
            guard let this = self else { fatalError() }
            return this.model[keyPath: keyPath]
            },
                set: { [weak self] value in self?.dispatch(messaging(value)) })
    }

    func update(_ model: Model) {
        self.model = model
    }
    
    private func addDerivedStore(_ derivedStore: Any, for keyPath: AnyKeyPath) {
        derivedStoresQueue.sync {
            derivedStores[keyPath] = derivedStore
        }
    }

    private func removeDerivedStore(for keyPath: AnyKeyPath) {
        _ = derivedStoresQueue.sync {
            derivedStores.removeValue(forKey: keyPath)
        }
    }
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Store: Equatable where Model: Equatable {
    public static func ==(lhs: Store<Page>, rhs: Store<Page>) -> Bool {
        if lhs.model != rhs.model { return false }
        return true
    }
}
