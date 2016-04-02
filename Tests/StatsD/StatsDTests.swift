import Foundation
import XCTest

@testable import StatsD

class MockSocket :Socket {
  var timesWritten = 0
  var dataWritten = [String]()

  internal func write(host: String, port: Int, data: String) -> (Bool, SocketError?) {
    timesWritten += 1
    return (true, nil)
  }
}

class StatsDTests: XCTestCase {
  func testInitSetsCorrectValues() {
    let port = 8125
    let host = "127.0.0.1"
    let socket:Socket = MockSocket()
    let statsD = StatsD(host: host, port: port, socket: socket)

    XCTAssertEqual(port, statsD.port, "Port should be equal")
    XCTAssertEqual(host, statsD.host, "Host should be equal")
    XCTAssertNotNil(statsD.socket, "Socket should not be nil")
  }

  func testIncrementShouldIncreaseBucketCountByOne() {
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: MockSocket())
    statsD.increment("mybucket")

    XCTAssertEqual(1, statsD.counters["mybucket"], "Counter for mybucket should be 1")
  }

  func testIncrementTwiceShouldIncreaseBucketCountByTwo() {
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: MockSocket())
    statsD.increment("mybucket")
    statsD.increment("mybucket")

    XCTAssertEqual(2, statsD.counters["mybucket"], "Counter for mybucket should be 2")
  }

  func testSendsDataAfterInterval() {
    let mockSocket = MockSocket()
    let expectation = expectationWithDescription("Send data after interval")
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: mockSocket) {
      XCTAssertEqual(1, mockSocket.timesWritten, "Expected to have called write")
      expectation.fulfill()
    }

    defer {
      statsD.dispose()
    }

    statsD.increment("mybucket")

    waitForExpectationsWithTimeout(2) { error in
      if let error = error {
        print("Error: \(error.localizedDescription)")
      }
    }
  }

  func testEmptiesBucketAfterSend() {
    let expectation = expectationWithDescription("Empty bucket after send")
    var statsD: StatsD?
    statsD = StatsD(host: "192.168.99.100", port: 8125, socket: MockSocket()) {
      XCTAssertEqual(0, statsD!.counters.count, "Expected to have emptied bucket")
      expectation.fulfill()
    }

    defer {
      statsD!.dispose()
    }

    statsD!.increment("mybucket")

    waitForExpectationsWithTimeout(2) { error in
      if let error = error {
        print("Error: \(error.localizedDescription)")
      }
    }
  }
}

extension StatsDTests {
    static var allTests: [(String, StatsDTests -> () throws -> Void)] {
        return [
          ("testInitSetsCorrectValues", testInitSetsCorrectValues),
          ("testIncrementShouldIncreaseBucketCountByOne", testIncrementShouldIncreaseBucketCountByOne),
          ("testSendsDataAfterInterval", testSendsDataAfterInterval),
          ("testEmptiesBucketAfterSend", testEmptiesBucketAfterSend)
        ]
    }
}
