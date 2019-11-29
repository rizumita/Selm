//
//  Task.swift
//  Selm
//
//  Created by Kyle Kirkland on 11/29/19.
//

import Foundation

public struct Task<Value, E: Error> {
    
    public typealias Observer = (Result<Value, E>) -> Void
    public typealias Work = (@escaping Observer) -> Void

    let work: Work
    
    public init(work: @escaping  Work) {
        self.work = work
    }
    
    public static func attempt<Msg>(
        mapResult: @escaping (Result<Value, E>) -> Msg,
        task: Task<Value, E>) -> Cmd<Msg>
    {
        return Cmd(value: [ { dispatch in
            task.work { result in
                let msg = mapResult(result)
                dispatch(msg)
            }
        }])
    }
    
    public func andThen<NewValue>(
        mapTask: @escaping (Value) -> Task<NewValue, E>) -> Task<NewValue, E> {
        return Task<NewValue, E> { result in
            self.work { (oldResult: Result<Value, E>) in
                switch oldResult {
                case .success(let valueA):
                    let taskB = mapTask(valueA)
                    taskB.work { (bResult: Result<NewValue, E>) in
                        result(bResult)
                    }
                case .failure(let error):
                    result(Result<NewValue, E>.failure(error))
                }
            }
        }
    }
    
}
