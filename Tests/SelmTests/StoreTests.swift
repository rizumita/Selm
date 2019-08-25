//
//  StoreTests.swift
//  SelmTests
//
//  Created by 和泉田 領一 on 2019/08/02.
//

import XCTest
import Combine
@testable import Selm

class StoreTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testObservable() {
        var cancellables = Set<AnyCancellable>()
        let exp = expectation(description: #function)
        exp.expectedFulfillmentCount = 2
        
        let store1 = Runner.create(initialize: View1.initialize, update: View1.update)
        store1.dispatch(.showView2)
        
        while store1.model.view2Model == nil {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
        
        let store2 = store1.derived(View1.Msg.view2Msg, \.view2Model)
        let store3 = store2?.derived(View2.Msg.view3Msg, \.view3Model)
        var expectedNum = 2
        store2?.willChange.sink(receiveValue: { model in
            defer { expectedNum += 1 }
            XCTAssertEqual(model.num, expectedNum)
            exp.fulfill()
            }).store(in: &cancellables)
        store1.dispatch(.setNum(1))
        store2?.dispatch(.setNum(2))
        store3?.dispatch(.setNum(3))

        waitForExpectations(timeout: 1.0)
    }
    
    class View1 {
        struct Model {
            var num: Int
            var view2Model: View2.Model? = .none
        }
        
        enum Msg {
            case view2Msg(View2.Msg)
            case setNum(Int)
            case showView2
        }
        
        static func initialize() -> (Model, Cmd<Msg>) {
            (Model(num: 0), .none)
        }
        
        static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>) {
            var model = model
            
            switch msg {
            case .view2Msg(let v2Msg):
                switch View2.update(v2Msg, model.view2Model!) {
                case (let m, let c, .noOp):
                    model.view2Model = m
                    return (model, c.map(Msg.view2Msg))
                case (_, _, .dismiss):
                    model.view2Model = .none
                    return (model, .none)
                }
                
            case .setNum(let num):
                model.num = num
                return (model, .none)
                
            case .showView2:
                let (m, c) = View2.initialize()
                model.view2Model = m
                return (model, c.map(Msg.view2Msg))
            }
        }
    }

    class View2 {
        struct Model: Equatable {
            var num: Int
            var view3Model = View3.Model(num: 0)
            
            static func == (lhs: StoreTests.View2.Model, rhs: StoreTests.View2.Model) -> Bool {
                if lhs.num != rhs.num { return false }
                return true
            }
        }

        enum Msg {
            case view3Msg(View3.Msg)
            case setNum(Int)
            case dismiss
        }
        
        enum ExtMsg {
            case noOp
            case dismiss
        }

        static func initialize() -> (Model, Cmd<Msg>) {
            (Model(num: 0), .none)
        }
        
        static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>, ExtMsg) {
            var model = model
            
            switch msg {
            case .view3Msg(let v3Msg):
                switch View3.update(v3Msg, model.view3Model) {
                case (let m, let c, .updatedNum(let num)):
                    model.view3Model = m
                    return (model, .batch([c.map(Msg.view3Msg), .ofMsg(.setNum(num))]), .noOp)
                }
            case .setNum(let num):
                model.num = num
                return (model, .none, .noOp)
                
            case .dismiss:
                return (model, .none, .dismiss)
            }
        }
    }

    class View3 {
        struct Model {
            var num: Int
       }

        enum Msg {
            case setNum(Int)
        }
        
        enum ExtMsg {
            case updatedNum(Int)
        }

        static func initialize() -> (Model, Cmd<Msg>) {
            (Model(num: 0), .none)
        }
        
        static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>, ExtMsg) {
            var model = model
            
            switch msg {
            case .setNum(let num):
                model.num = num
                return (model, .none, .updatedNum(num))
            }
        }
    }
}
