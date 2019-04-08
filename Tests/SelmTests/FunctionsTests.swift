import XCTest
import Foundation
@testable import Selm

final class FunctionsTests: XCTestCase {
    func testDependsOnOptional() {
        let dep: DependsOnOptional<String> = dependsOn()

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
        let dep: DependsOn<String> = dependsOn()

        var called = false

        dep("test") { v in
            XCTAssertEqual(v, "test")
            called = true
        }
        XCTAssertTrue(called)

        called = false

        dep("test") { v in
            XCTAssertEqual(v, "test")
            called = true
        }
        XCTAssertFalse(called)

        called = false

        dep("test updated") { v in
            XCTAssertEqual(v, "test updated")
            called = true
        }
        XCTAssertTrue(called)
    }

    func testDependsOnReturnOptional() {
        let dep: DependsOnOptionalReturn<String, String> = dependsOn(defaultValue: "")

        XCTAssertEqual(dep("test") { $0 }, "test")
        XCTAssertEqual(dep("test") { $0 }, "")
        XCTAssertEqual(dep(.none) { $0 }, "")
    }

    func testDependsOnReturn() {
        let dep: DependsOnReturn<String, String> = dependsOn(defaultValue: "")

        XCTAssertEqual(dep("test") { $0 }, "test")
        XCTAssertEqual(dep("test") { $0 }, "")
    }

    func testChangesOn() {
        let cha: ChangesOn<String> = changesOn()

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

        called = false

        cha(.none) { v in
            XCTAssertNil(v)
            called = true
        }
        XCTAssertFalse(called)
    }
}
