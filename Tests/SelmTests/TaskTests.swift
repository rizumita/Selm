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
}
