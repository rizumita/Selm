import XCTest
import Foundation
@testable import Selm

final class RunnerTests: XCTestCase {
    func testCreate() {
        let exp = expectation(description: #function)
        exp.expectedFulfillmentCount = 3
        exp.assertForOverFulfill = true

        var firstDispatched  = false
        var secondDispatched = false
        var thirdDispatched  = false
        let dispatch = Runner<Model, Msg>.create(initialize: { return (Model(string: "test"), Cmd.ofMsg(.first)) },
                                                 update: { msg, model in
                                                     defer { exp.fulfill() }

                                                     var model = model
                                                     model.string = "test updated"

                                                     switch msg {
                                                     case .first:
                                                         firstDispatched = true
                                                         return (model, Cmd.ofMsg(.second))
                                                     case .second:
                                                         secondDispatched = true
                                                         return (model, Cmd.none)
                                                     case .third:
                                                         thirdDispatched = true
                                                         return (model, Cmd.none)
                                                     }
                                                 },
                                                 view: { model, dispatch in
                                                     XCTAssertEqual(model.string, "test updated")
                                                 })
        dispatch(.third)

        waitForExpectations(timeout: 100.0)

        XCTAssertTrue(firstDispatched)
        XCTAssertTrue(secondDispatched)
        XCTAssertTrue(thirdDispatched)
    }

    struct Model {
        var string: String
    }

    enum Msg {
        case first
        case second
        case third
    }
}
