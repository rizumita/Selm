//
//  Task.swift
//  Selm
//
//  Created by Kyle Kirkland on 11/29/19.
//

import Foundation

public struct Task<Value> {
    
    public typealias Observer = (Result<Value, Error>) -> Void
    public typealias Work = (@escaping Observer) -> Void

    let work: Work
    
    public init(work: @escaping  Work) {
        self.work = work
    }
    
    public init(result: Result<Value, Error>) {
        self.init { fulfill in
            fulfill(result)
        }
    }
    
    public init(value: Value) {
        self.init(result: .success(value))
    }
    
    public static func attempt<Msg>(
        mapResult: @escaping (Result<Value, Error>) -> Msg,
        task: Task<Value>) -> Cmd<Msg>
    {
        return Cmd(value: [ { dispatch in
            task.work { result in
                let msg = mapResult(result)
                dispatch(msg)
            }
        }])
    }
    
    public func flatMap<NewValue>(
        mapTask: @escaping (Value) -> Task<NewValue>) -> Task<NewValue> {
        return Task<NewValue> { fulfill in
            self.work { (oldResult: Result<Value, Error>) in
                do {
                    let mappedTask = mapTask(try oldResult.get())
                    mappedTask.work(fulfill)
                } catch let error {
                    fulfill(.failure(error))
                }
            }
        }
    }
    
    public func map<NewValue>(transform: @escaping (Value) -> NewValue) -> Task<NewValue> {
        return flatMap { value in
            return Task<NewValue>(value: transform(value))
        }
    }
    
}
