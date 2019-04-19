import XCTest
import Foundation
@testable import Selm

final class FunctionsTests: XCTestCase {
    struct Model {
        var int: Int
        var string: String
        var bool: Bool
    }
    
    func testDependsOn_1() {
        var model = Model(int: 0, string: "", bool: false)

        var r = dependsOn(\.int, model) { int in 1 }
        XCTAssertEqual(r, 1)

        r = dependsOn(\.int, model) { int in 2 }
        XCTAssertEqual(r, 1)

        model.int = 1
        r = dependsOn(\.int, model) { int in 3 }
        XCTAssertEqual(r, 3)
    }

    func testDependsOn_2() {
        var model = Model(int: 0, string: "", bool: false)

        var r = dependsOn(\.int, \.string, model) { int in 1 }
        XCTAssertEqual(r, 1)

        r = dependsOn(\.int, \.string, model) { int in 2 }
        XCTAssertEqual(r, 1)

        model.int = 1
        r = dependsOn(\.int, \.string, model) { int in 3 }
        XCTAssertEqual(r, 3)
    }

    func testDependsOn_3() {
        var model = Model(int: 0, string: "", bool: false)

        var r = dependsOn(\.int, \.string, \.bool, model) { int in 1 }
        XCTAssertEqual(r, 1)

        r = dependsOn(\.int, \.string, \.bool, model) { int in 2 }
        XCTAssertEqual(r, 1)

        model.int = 1
        r = dependsOn(\.int, \.string, \.bool, model) { int in 3 }
        XCTAssertEqual(r, 3)
    }
}
