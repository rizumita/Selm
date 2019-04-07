import XCTest
@testable import Selm

final class SelmTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Selm().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
