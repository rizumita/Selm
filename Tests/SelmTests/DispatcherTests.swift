import XCTest
import Foundation
@testable import Selm

final class DispatcherTests: XCTestCase {
    func testSetDispatchThunk() {
        let dispatcher = Dispatcher<Msg>()
        var msg: Msg?
        dispatcher.setDispatchThunk { msg = $0 }
        dispatcher.dispatch(.first)

        XCTAssertEqual(msg, Msg.first)
    }

    enum Msg: Equatable {
        case first
    }
}
