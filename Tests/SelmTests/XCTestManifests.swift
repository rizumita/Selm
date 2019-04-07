import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CmdTests.allTests),
        testCase(DispatcherTests.allTests),
        testCase(RunnerTests.allTests),
        testCase(FunctionsTests.allTests),
    ]
}
#endif
