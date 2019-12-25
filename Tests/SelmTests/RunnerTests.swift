import XCTest
import Foundation
@testable import Selm

final class RunnerTests: XCTestCase {
    func testCreate() {
        let store = Runner<Page>.create(initialize: Page.initialize)
        store.dispatch(.third)
        XCTAssertEqual(store.model.string, "third")
    }

    func testAsync() {
        let store = Runner<Page>.create(initialize: Page.initialize)
        store.dispatch(.first)
        store.dispatch(.third)
        XCTAssertEqual(store.model.string, "third")
    }

    enum Page: SelmPage {
        struct Model: SelmModel {
            var string: String
        }

        enum Msg {
            case first
            case second
            case third
        }

        static func initialize() -> (Model, Cmd<Msg>) {
            (Model(string: "test"), .none)
        }

        static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>) {
            switch msg {
            case .first:
                return (model.modified(\.string, "first"),
                    Cmd.ofAsyncMsg { fulfill in
                        DispatchQueue
                            .global()
                            .asyncAfter(deadline: .now() + .seconds(1)) {
                                fulfill(.second)
                            }
                    })
            case .second:
                return (model.modified(\.string, "second"), .none)
            case .third:
                return (model.modified(\.string, "third"), .none)
            }
        }
    }
}
