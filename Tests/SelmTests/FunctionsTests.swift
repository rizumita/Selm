import XCTest
import Foundation
@testable import Selm

final class FunctionsTests: XCTestCase {
    func testDependsOnOptional() {
        let dep = dependsOn(String?.none)

        var called = false

        dep(.none) { v in called = true }
        XCTAssertFalse(called)

        dep("test") { v in
            XCTAssertEqual(v, "test")
            called = true
        }
        XCTAssertTrue(called)

        called = false

        dep("test") { v in called = true }
        XCTAssertFalse(called)

        dep("test updated") { v in
            XCTAssertEqual(v, "test updated")
            called = true
        }
        XCTAssertTrue(called)
    }

    func testDependsOn() {
        let dep = dependsOn("test")

        var called = false

        dep("test") { v in
            XCTAssertEqual(v, "test")
            called = true
        }
        XCTAssertFalse(called)

        dep("test updated") { v in
            XCTAssertEqual(v, "test updated")
            called = true
        }
        XCTAssertTrue(called)
    }

    func testChangesOn() {
        let cha = changesOn(String?.none)

        var called = false

        cha("test") { v in
            XCTAssertEqual(v, "test")
            called = true
        }
        XCTAssertTrue(called)

        called = false

        cha(.none) { v in
            XCTAssertNil(v)
            called = true
        }
        XCTAssertTrue(called)
    }
}
