//
//  Step.swift
//  SelmSample
//
//  Created by 和泉田 領一 on 2019/07/07.
//

import Foundation

enum Step: Equatable {
    case up
    case down
    
    func step(count: Int) -> Int {
        switch self {
        case .up: return count + 1
        case .down: return count - 1
        }
    }
    
    var string: String {
        switch self {
        case .up: return "Up"
        case .down: return "Down"
        }
    }
}
