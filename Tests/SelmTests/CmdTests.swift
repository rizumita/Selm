import XCTest
import Foundation
@testable import Selm

final class CmdTests: XCTestCase {
    func testNone() {
        XCTAssertTrue(Cmd<Msg1>.none.value.isEmpty)
    }

    func testOfMsg() {
        var msg: Msg1?
        let dispatch: Dispatch<Msg1> = { msg = $0 }

        let cmd = Cmd<Msg1>.ofMsg(.first)
        cmd.dispatch(dispatch)

        XCTAssertEqual(cmd.value.count, 1)
        XCTAssertEqual(msg, Msg1.first)
    }

    func testOfMsgOptionalWithMsg() {
        var msg: Msg1?
        let dispatch: Dispatch<Msg1> = { msg = $0 }

        let cmd = Cmd<Msg1>.ofMsgOptional(.first)
        cmd.dispatch(dispatch)

        XCTAssertEqual(cmd.value.count, 1)
        XCTAssertEqual(msg, Msg1.first)
    }

    func testOfMsgOptionalWithNil() {
        var msg: Msg1?
        let dispatch: Dispatch<Msg1> = { msg = $0 }

        let cmd = Cmd<Msg1>.ofMsgOptional(.none)
        cmd.dispatch(dispatch)

        XCTAssertEqual(cmd.value.count, 1)
        XCTAssertNil(msg)
    }

    func testMapStatic() {
        var msg: Msg1?
        let dispatch: Dispatch<Msg1> = { msg = $0 }

        let cmdMsg2 = Cmd<Msg2>.ofMsg(.fourth)
        let cmdMsg1 = Cmd<Msg1>.map { (msg2: Msg2) in
            XCTAssertEqual(msg2, Msg2.fourth)
            return Msg1.third
        }(cmdMsg2)
        cmdMsg1.dispatch(dispatch)

        XCTAssertEqual(msg, Msg1.third)
    }

    func testMap() {
        var msg: Msg1?
        let dispatch: Dispatch<Msg1> = { msg = $0 }

        let cmdMsg2 = Cmd<Msg2>.ofMsg(.fourth)
        let cmdMsg1 = cmdMsg2.map { msg2 -> Msg1 in
            XCTAssertEqual(msg2, Msg2.fourth)
            return Msg1.third
        }
        cmdMsg1.dispatch(dispatch)

        XCTAssertEqual(msg, Msg1.third)
    }

    func testBatch() {
        var msg: Msg1?
        let dispatch: Dispatch<Msg1> = {
            if msg == .none {
                XCTAssertEqual($0, Msg1.first)
            } else if msg == .first {
                XCTAssertEqual($0, Msg1.second)
            } else if msg == .second {
                XCTAssertEqual($0, Msg1.third)
            }
            msg = $0
        }

        let subCmd1 = Cmd<Msg1>.ofMsg(.first)
        let subCmd2 = Cmd<Msg1>.ofMsg(.second)
        let subCmd3 = Cmd<Msg1>.ofMsg(.third)
        let cmd     = Cmd<Msg1>.batch([subCmd1, subCmd2, subCmd3])
        cmd.dispatch(dispatch)

        XCTAssertEqual(cmd.value.count, 3)
        XCTAssertEqual(msg, Msg1.third)
    }

    func testOfSub() {
        var msg: Msg1?
        let dispatch: Dispatch<Msg1> = { msg = $0 }

        let cmd = Cmd<Msg1>.ofSub { (dispatch: @escaping Dispatch<Msg1>) in dispatch(.third) }
        cmd.dispatch(dispatch)

        XCTAssertEqual(cmd.value.count, 1)
        XCTAssertEqual(msg, Msg1.third)
    }

    func testOfAsyncMsg() {
        let exp = expectation(description: #function)
        var msg: Msg1?
        let dispatch: Dispatch<Msg1> = { msg = $0 }

        let cmd = Cmd<Msg1>.ofAsyncMsg { fulfill in
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
                fulfill(.second)
                exp.fulfill()
            }
        }
        cmd.dispatch(dispatch)

        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(cmd.value.count, 1)
        XCTAssertEqual(msg, Msg1.second)
    }

    func testOfAsyncMsgOptionalWithMsg() {
        let exp = expectation(description: #function)
        var msg: Msg1?
        let dispatch: Dispatch<Msg1> = { msg = $0 }

        let cmd = Cmd<Msg1>.ofAsyncMsgOptional { fulfill in
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
                fulfill(.second)
                exp.fulfill()
            }
        }
        cmd.dispatch(dispatch)

        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(cmd.value.count, 1)
        XCTAssertEqual(msg, Msg1.second)
    }

    func testOfAsyncMsgOptionalWithNil() {
        let exp = expectation(description: #function)
        var msg: Msg1?
        let dispatch: Dispatch<Msg1> = { msg = $0 }

        let cmd = Cmd<Msg1>.ofAsyncMsgOptional { fulfill in
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
                fulfill(.none)
                exp.fulfill()
            }
        }
        cmd.dispatch(dispatch)

        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(cmd.value.count, 1)
        XCTAssertNil(msg)
    }

    func testAsyncCmd() {
        let exp = expectation(description: #function)
        var msg: Msg1?
        let dispatch: Dispatch<Msg1> = { msg = $0 }

        let cmd = Cmd<Msg1>.ofAsyncCmd { fulfill in
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
                fulfill(Cmd.ofMsg(.second))
                exp.fulfill()
            }
        }
        cmd.dispatch(dispatch)

        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(cmd.value.count, 1)
        XCTAssertEqual(msg, Msg1.second)
    }

    func testOfAsyncCmdOptionalWithMsg() {
        let exp = expectation(description: #function)
        var msg: Msg1?
        let dispatch: Dispatch<Msg1> = { msg = $0 }

        let cmd = Cmd<Msg1>.ofAsyncCmdOptional { fulfill in
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
                fulfill(Cmd.ofMsg(.second))
                exp.fulfill()
            }
        }
        cmd.dispatch(dispatch)

        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(cmd.value.count, 1)
        XCTAssertEqual(msg, Msg1.second)
    }

    func testOfAsyncCmdOptionalWithNil() {
        let exp = expectation(description: #function)
        var msg: Msg1?
        let dispatch: Dispatch<Msg1> = { msg = $0 }

        let cmd = Cmd<Msg1>.ofAsyncCmdOptional { fulfill in
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
                fulfill(Cmd.none)
                exp.fulfill()
            }
        }
        cmd.dispatch(dispatch)

        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(cmd.value.count, 1)
        XCTAssertNil(msg)
    }

    enum Msg1: Equatable {
        case first
        case second
        case third
    }

    enum Msg2: Equatable {
        case fourth
        case fifth
        case sixth
    }
}
