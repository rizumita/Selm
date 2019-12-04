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
    
    public let id = UUID()
    public var objectWillChange: AnyPublisher<Model, Never> {
        return willChange.eraseToAnyPublisher()
    }
    
    @Published public private(set) var model: Model {
        willSet {
            if isSubscribing {
                willChange.send(newValue)
            }
        }
    }
    public let dispatch: Dispatch<Msg>
    
    private var willChange = PassthroughSubject<Model, Never>()
    private var isSubscribing: Bool = false
    private var substores = [AnyKeyPath : Any]()
    private let substoreQueue = DispatchQueue(label: "Selm.Store.substoreQueue")
    private var cancellables = Set<AnyCancellable>()
    
    public init(model: Model, dispatch: @escaping Dispatch<Msg> = { _ in }) {
        self.model = model
        self.dispatch = dispatch
        self.isSubscribing = true
    }

    deinit {
        print("\(self) deinit")
    }

    public func subscribe() {
        guard !isSubscribing else { return }
        
        runOnQueue {
            self.isSubscribing = true
            self.willChange.send(self.model)
        }
    }
    
    public func unsubscribe() {
        guard isSubscribing else { return }
        
        runOnQueue {
            self.isSubscribing = false
        }
    }

    public func derived<SubPage>(_ messaging: @escaping (SubPage.Msg) -> Msg,
                                 _ keyPath: KeyPath<Model, SubPage.Model>,
                                 isSubscribing: Bool = false) -> Store<SubPage> {
        if let substore = substores[keyPath] as? Store<SubPage> {
            return substore
        }
        
        let result = Store<SubPage>(model: model[keyPath: keyPath], dispatch: { self.dispatch(messaging($0)) })
        $model.share().map(keyPath).sink { [weak result] model in
            result?.model = model
        }.store(in: &cancellables)

        result.isSubscribing = isSubscribing
        
        addSubstore(result, for: keyPath)

        return result
    }

    public func derived<SubPage>(_ messaging: @escaping (SubPage.Msg) -> Msg,
                                 _ keyPath: KeyPath<Model, SubPage.Model?>,
                                 isSubscribing: Bool = true) -> Store<SubPage>? {
        if let substore = substores[keyPath] as? Store<SubPage> {
            return substore
        }
        
        guard let m = model[keyPath: keyPath] else { return .none }
        let result = Store<SubPage>(model: m, dispatch: { self.dispatch(messaging($0)) })
        
        $model.share().map(keyPath).sink { [weak self, weak result] model in
            guard let model = model else {
                self?.removeSubstore(for: keyPath)
                return
            }
            result?.model = model
        }.store(in: &cancellables)

        result.isSubscribing = isSubscribing

        addSubstore(result, for: keyPath)
        
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
    
    private func runOnQueue(_ f: @escaping () -> ()) {
        let label = String(cString: __dispatch_queue_get_label(.none), encoding: .utf8)
        
        if label == DispatchQueue.main.label {
            f()
        } else {
            DispatchQueue.main.sync {
                f()
            }
        }
    }

    private func addSubstore(_ substore: Any, for keyPath: AnyKeyPath) {
        substoreQueue.sync {
            substores[keyPath] = substore
        }
    }
    
    private func removeSubstore(for keyPath: AnyKeyPath) {
        substoreQueue.sync {
            substores.removeValue(forKey: keyPath)
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
