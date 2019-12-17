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
    
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct Task<Value, ErrorType: Swift.Error> {
    
    public typealias Observer = (Result<Value, ErrorType>) -> Void
    public typealias Work = (@escaping Observer) -> Void

    let work: Work
    let cancellablesHolder = CancellablesHolder()
    
    public init(work: @escaping  Work) {
        self.work = work
    }
    
    public init(workWithCancellables: @escaping (@escaping Observer, inout Set<AnyCancellable>) -> Void) {
        let holder = self.cancellablesHolder
        self.work = { fulfill in
            workWithCancellables(fulfill, &holder.cancellables)
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
    
    public static func attempt<Msg>(
        toMsg: @escaping (Result<Value, ErrorType>) -> Msg) -> (Task<Value, ErrorType>) -> Cmd<Msg> {
        return { task in
            return .ofTask(
                toMsg: toMsg,
                work: { fulfill in
                    task.work { result in
                        _ = task
                        fulfill(result)
                    }
                }
            )
        }
    }
    
    public static func attempt<Msg>(toCmd: @escaping (Result<Value, ErrorType>) -> Cmd<Msg>) -> (Task<Value, ErrorType>) -> Cmd<Msg> {
        { task in
            .ofTask(toCmd: toCmd) { fulfill in
                task.work { result in
                    _ = task
                    fulfill(result)
                }
            }
        }
    }
    
    public func flatMap<NewValue>(
        mapTask: @escaping (Value) -> Task<NewValue, ErrorType>) -> Task<NewValue, ErrorType> {
        return Task<NewValue, ErrorType> { fulfill in
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
        return flatMap { value in
            return Task<NewValue, ErrorType>(value: transform(value))
        }
    }
    
}
