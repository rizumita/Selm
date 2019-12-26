//
// Created by Ryoichi Izumita on 2019/12/25.
// Copyright (c) 2019 CAPH TECH. All rights reserved.
//

import XCTest
import Foundation
import Combine
@testable import Selm

class TaskTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testPublisher() {
        let exe = PassthroughSubject<Int, NSError>()

        let exp = expectation(description: #function)

        let cmd = Task(exe).attemptToMsg { result in
            print(result)
            exp.fulfill()
        }

        cmd.dispatch {}
        exe.send(completion: .failure(NSError(domain: "domain", code: 1)))

        waitForExpectations(timeout: 1.0)
    }

    func testPublisherWithUntil() {
        let until = PassthroughSubject<(), Never>()
        let exe   = PassthroughSubject<Int, NSError>()

        let exp = expectation(description: #function)

        let cmd = Task(exe.handleEvents(receiveCancel: { exp.fulfill() }), until: until)
            .attemptToMsg { result in
                print(result)
            }

        cmd.dispatch {}
        exe.send(1)
        until.send(())

        waitForExpectations(timeout: 1.0)
    }

    func testDematerialize() {
        let expSuccess = expectation(description: "success")
        expSuccess.expectedFulfillmentCount = 2
        let expFailure = expectation(description: "failure")
        expFailure.expectedFulfillmentCount = 1

        let exe = PassthroughSubject<Result<Int, NSError>, Never>()
        var num = 0
        Task(exe).dematerialize().work { result in
            switch result {
            case let .success(value):
                XCTAssertEqual(value, num)
                expSuccess.fulfill()
            case let .failure(error):
                XCTAssertEqual(error.domain, "domain")
                expFailure.fulfill()
            }
        }

        num = 1
        exe.send(.success(num))
        
        exe.send(.failure(NSError(domain: "domain", code: 1)))

        num = 2
        exe.send(.success(num))

        waitForExpectations(timeout: 1.0)
    }
}
