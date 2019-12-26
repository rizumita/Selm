//
//  Task.swift
//  Selm
//
//  Created by Kyle Kirkland on 11/29/19.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
class CancellablesHolder {

    var cancellables = Set<AnyCancellable>()

    func cancel() {
        cancellables.forEach { $0.cancel() }
    }

}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct Task<Value, ErrorType: Swift.Error> {

    public typealias Observer = (Result<Value, ErrorType>) -> Void
    public typealias Work = (@escaping Observer) -> Void

    let work: Work
    let cancellablesHolder = CancellablesHolder()

    public init(work: @escaping Work) {
        self.work = work
    }

    public init(workWithCancellables: @escaping (@escaping Observer, inout Set<AnyCancellable>) -> Void) {
        let holder = self.cancellablesHolder
        self.work = { fulfill in
            workWithCancellables(fulfill, &holder.cancellables)
        }
    }

    public init<Until: Publisher>(runUntil: Until,
                                  workWithCancellables: @escaping (@escaping Observer, inout Set<AnyCancellable>) -> Void) where Until.Failure == Never {
        let holder = self.cancellablesHolder
        self.work = { fulfill in
            workWithCancellables(fulfill, &holder.cancellables)
        }
        runUntil.sink { _ in
            holder.cancel()
        }.store(in: &holder.cancellables)
    }

    public init<P: Publisher>(_ publisher: P) where P.Output == Value, P.Failure == ErrorType {
        let holder = self.cancellablesHolder
        self.work = { fulfill in
            publisher.handleEvents(receiveCompletion: { _ in
                    holder.cancel()
                }).sink(receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        fulfill(.failure(error))
                    case .finished:
                        ()
                    }
                }, receiveValue: { value in fulfill(.success(value)) })
                .store(in: &holder.cancellables)
        }
    }

    public init<P: Publisher, Until: Publisher>(_ publisher: P,
                                                until: Until) where P.Output == Value, P.Failure == ErrorType, Until.Failure == Never {
        let holder = self.cancellablesHolder
        self.work = { fulfill in
            publisher.handleEvents(receiveCompletion: { _ in
                    holder.cancel()
                }).sink(receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        fulfill(.failure(error))
                    case .finished:
                        ()
                    }
                }, receiveValue: { value in fulfill(.success(value)) })
                .store(in: &holder.cancellables)

            until.sink { [weak holder]_ in
                holder?.cancel()
            }.store(in: &holder.cancellables)
        }
    }

    public init(result: Result<Value, ErrorType>) {
        self.init { fulfill in
            fulfill(result)
        }
    }

    public init(value: Value) {
        self.init(result: .success(value))
    }

    public func attemptToMsg<Msg>(_ toMsg: @escaping (Result<Value, ErrorType>) -> Msg) -> Cmd<Msg> {
        .ofTask(toMsg: toMsg) { fulfill in
            self.work { result in
                fulfill(result)
            }
        }
    }

    public func attemptToMsgOptional<Msg>(_ toMsgOptional: @escaping (Result<Value, ErrorType>) -> Msg?) -> Cmd<Msg> {
        .ofTask(toMsgOptional: toMsgOptional) { fulfill in
            self.work { result in
                fulfill(result)
            }
        }
    }

    public func attemptToCmd<Msg>(_ toCmd: @escaping (Result<Value, ErrorType>) -> Cmd<Msg>) -> Cmd<Msg> {
        .ofTask(toCmd: toCmd) { fulfill in
            self.work { result in
                fulfill(result)
            }
        }
    }

    public static func attemptToMsg<Msg>(_ toMsg: @escaping (Result<Value, ErrorType>) -> Msg) -> (Task<Value, ErrorType>) -> Cmd<Msg> {
        { task in
            .ofTask(
                toMsg: toMsg,
                work: { fulfill in
                    task.work { result in
                        fulfill(result)
                    }
                }
            )
        }
    }

    public static func attemptToMsgOptional<Msg>(_ toMsgOptional: @escaping (Result<Value, ErrorType>) -> Msg?) -> (Task<Value, ErrorType>) -> Cmd<Msg> {
        { task in
            .ofTask(
                toMsgOptional: toMsgOptional,
                work: { fulfill in
                    task.work { result in
                        fulfill(result)
                    }
                }
            )
        }
    }

    public static func attemptToCmd<Msg>(_ toCmd: @escaping (Result<Value, ErrorType>) -> Cmd<Msg>) -> (Task<Value, ErrorType>) -> Cmd<Msg> {
        { task in
            .ofTask(toCmd: toCmd) { fulfill in
                task.work { result in
                    fulfill(result)
                }
            }
        }
    }

    public func flatMap<NewValue>(mapTask: @escaping (Value) -> Task<NewValue, ErrorType>) -> Task<NewValue, ErrorType> {
        Task<NewValue, ErrorType> { fulfill in
            self.work { (oldResult: Result<Value, ErrorType>) in
                switch oldResult {
                case .success(let oldValue):
                    let mappedTask = mapTask(oldValue)
                    mappedTask.work(fulfill)
                case .failure(let error):
                    fulfill(.failure(error))
                }
            }
        }
    }

    public func map<NewValue>(transform: @escaping (Value) -> NewValue) -> Task<NewValue, ErrorType> {
        flatMap { value in
            Task<NewValue, ErrorType>(value: transform(value))
        }
    }
}
