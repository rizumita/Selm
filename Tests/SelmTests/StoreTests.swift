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

    func testObservable() throws {
        let store1 = Runner<Page1>.create(initialize: Page1.initialize)
        store1.dispatch(.showPage2)
        let store2: Store<Page2> = try XCTUnwrap(store1.derived(Page1.Msg.page2Msg, \.page2Model))
        let store3: Store<Page3> = store2.derived(Page2.Msg.page3Msg, \.page3Model)

        store1.dispatch(.setNum(1))
        XCTAssertEqual(store1.model.num, 1)
        XCTAssertEqual(store2.model.num, 0)
        XCTAssertEqual(store3.model.num, 0)

        store2.dispatch(.setNum(2))
        XCTAssertEqual(store1.model.num, 1)
        XCTAssertEqual(store2.model.num, 2)
        XCTAssertEqual(store3.model.num, 0)

        store3.dispatch(.setNum(3))
        XCTAssertEqual(store1.model.num, 1)
        XCTAssertEqual(store2.model.num, 3)
        XCTAssertEqual(store3.model.num, 3)
    }

    enum Page1: SelmPage {
        struct Model: SelmModel, Equatable {
            var num:        Int
            var page2Model: Page2.Model? = .none
        }

        enum Msg {
            case page2Msg(Page2.Msg)
            case setNum(Int)
            case showPage2
        }

        static func initialize() -> (Model, Cmd<Msg>) {
            (Model(num: 0), .none)
        }

        static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>) {
            switch msg {
            case .page2Msg(let v2Msg):
                switch Page2.update(v2Msg, model.page2Model!) {
                case (let m, let c, .noOp):
                    return (model.modified(\.page2Model, m), c.map(Msg.page2Msg))
                case (_, _, .dismiss):
                    return (model.modified(\.page2Model, .none), .none)
                }

            case .setNum(let num):
                return (model.modified(\.num, num), .none)

            case .showPage2:
                let (m, c) = Page2.initialize()
                return (model.modified(\.page2Model, m), c.map(Msg.page2Msg))
            }
        }
    }

    enum Page2: SelmPageExt {
        struct Model: SelmModel, Equatable {
            var num: Int
            var page3Model = Page3.Model(num: 0)

            static func ==(lhs: StoreTests.Page2.Model, rhs: StoreTests.Page2.Model) -> Bool {
                if lhs.num != rhs.num { return false }
                return true
            }
        }

        enum Msg {
            case page3Msg(Page3.Msg)
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
            switch msg {
            case .page3Msg(let v3Msg):
                switch Page3.update(v3Msg, model.page3Model) {
                case (let m, let c, .updatedNum(let num)):
                    return (model.modified(\.page3Model, m), .batch([c.map(Msg.page3Msg), .ofMsg(.setNum(num))]), .noOp)
                }
            case .setNum(let num):
                return (model.modified(\.num, num), .none, .noOp)

            case .dismiss:
                return (model, .none, .dismiss)
            }
        }
    }

    enum Page3: SelmPageExt {
        struct Model: SelmModel, Equatable {
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
            switch msg {
            case .setNum(let num):
                return (model.modified(\.num, num), .none, .updatedNum(num))
            }
        }
    }
}
