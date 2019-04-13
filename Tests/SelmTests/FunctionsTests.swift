import XCTest
import Foundation
@testable import Selm

final class FunctionsTests: XCTestCase {
    func testDependsOnWithNonOptional() {
        let dep = dependsOn(String.self)

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

    func testDependsOnWithOptional() {
        let dep = dependsOn(String?.self)

        var called = false

        dep(.none) { v in
            called = true
        }
        XCTAssertTrue(called)

        called = false

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

    func testDependsOn2() {
        let dep: DependsOn2<String, String?> = dependsOn()

        var called = false

        dep("test", .none) { v1, v2 in
            XCTAssertEqual(v1, "test")
            XCTAssertNil(v2)
            called = true
        }
        XCTAssertTrue(called)

        called = false

        dep("test", "test") { v1, v2 in
            XCTAssertEqual(v1, "test")
            XCTAssertEqual(v2, "test")
            called = true
        }
        XCTAssertTrue(called)

        called = false

        dep("test", "test") { _, _ in
            called = true
        }
        XCTAssertFalse(called)
    }
}
