import Foundation
import XCTest

@testable import StatsD

class MockSocket :Socket {
  var timesWritten = 0
  var dataWritten = [String]()

  internal func write(host: String, port: Int, data: String) -> (Bool, SocketError?) {
    timesWritten += 1
    return (true, SocketError.FailedToSendData)
  }
}

class StatsDTests: XCTestCase {
  func testConvenienceInitSetsCorrectValues() {
    let port = 8125
    let host = "127.0.0.2"
    let socket:Socket = MockSocket()
    let statsD = StatsD(host: host, port: port, socket: socket)
    defer {
      statsD.dispose()
    }

    XCTAssertEqual(port, statsD.port, "Port should be equal")
    XCTAssertEqual(host, statsD.host, "Host should be equal")
    XCTAssertNotNil(statsD.socket, "Socket should not be nil")
  }

  func testInitSetsCorrectValues() {
    let port = 8125
    let host = "127.0.0.2"
    let socket = MockSocket()
    let interval = 15.0
    let statsD = StatsD(host: host, port: port, socket: socket, interval: interval)
    defer {
      statsD.dispose()
    }

    XCTAssertEqual(port, statsD.port, "Port should be equal")
    XCTAssertEqual(host, statsD.host, "Host should be equal")
    XCTAssertEqual(interval, statsD.sendInterval, "Send interval should be equal")
    XCTAssertNotNil(statsD.socket, "Socket should not be nil")
  }

  func testIncrementShouldIncreaseBufferByOne() {
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: MockSocket())
    defer {
      statsD.dispose()
    }

    statsD.increment("mybucket")

    XCTAssertEqual(1, statsD.buffer.count, "Buffer should container 1 item")
  }

  func testIncrementTwiceShouldIncreaseBufferByTwo() {
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: MockSocket())
    defer {
      statsD.dispose()
    }

    statsD.increment("mybucket")
    statsD.increment("mybucket")

    XCTAssertEqual(2, statsD.buffer.count, "Buffer should container 2 items")
  }

  func testIncrementShouldSetCorrectBuffer() {
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: MockSocket())
    defer {
      statsD.dispose()
    }

    statsD.increment("mybucket")

    XCTAssertEqual("mybucket:1|c", statsD.buffer[0], "Buffer should contain correct value")
  }

  func testTimerShouldIncreaseBufferByOne() {
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: MockSocket())
    defer {
      statsD.dispose()
    }

    statsD.timer("mybucket") {
      print("Setting Timer")
    }

    XCTAssertEqual(1, statsD.buffer.count, "Buffer should container 1 items")
  }

  func testGaugeShouldSetCorrectBuffer() {
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: MockSocket())
    defer {
      statsD.dispose()
    }

    statsD.gauge("mybucket", value: 333)

    XCTAssertEqual("mybucket:333|g", statsD.buffer[0], "Buffer should contain correct value")
  }

  #if os(Linux)
  func testTimerShouldSetCorrectBuffer() {
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: MockSocket())
    defer {
      statsD.dispose()
    }

    statsD.timer("mybucket") {
      print("Setting Timer")
    }


    let buffer = statsD.buffer[0]

    XCTAssertEqual(
      "mybucket",
      buffer.componentsSeparatedByString(":")[0],
      "Buffer should contain bucket")
    XCTAssertTrue(
      Float(buffer.componentsSeparatedByString(":")[1].componentsSeparatedByString("|")[0]) > 0,
      "Buffer should contain duration")
  }

  func testSendsDataAfterInterval() {
    let mockSocket = MockSocket()
    let expectation = expectationWithDescription("Send data after interval")
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: mockSocket, interval: 0.1) {
      (success: Bool, error: SocketError?) in
        XCTAssertEqual(1, mockSocket.timesWritten, "Expected to have called write")
        expectation.fulfill()
    }

    defer {
      statsD.dispose()
    }

    statsD.increment("mybucket")

    waitForExpectationsWithTimeout(3) { error in
      if let error = error {
        print("Error: \(error.localizedDescription)")
      }
    }
  }

  func testEmptiesBucketAfterSend() {
    let expectation = expectationWithDescription("Empty bucket after send")
    var statsD: StatsD?
    statsD = StatsD(host: "192.168.99.100", port: 8125, socket: MockSocket(), interval: 0.1) {
      (success: Bool, error: SocketError?) in
        XCTAssertEqual(0, statsD!.buffer.count, "Expected to have emptied bucket")
        expectation.fulfill()
    }

    defer {
      statsD!.dispose()
    }

    statsD!.increment("mybucket")

    waitForExpectationsWithTimeout(3) { error in
      if let error = error {
        print("Error: \(error.localizedDescription)")
      }
    }
  }

  func testDoesCallbackWithParametersAfterSend() {
    let mockSocket = MockSocket()
    let expectation = expectationWithDescription("Send data after interval")
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: mockSocket, interval: 0.1) {
      (success: Bool, error: SocketError?) in
        XCTAssertTrue(success, "Expected to have returned success on callback")
        XCTAssertNotNil(error, "Expected to have returned error on callback")
        expectation.fulfill()
    }

    defer {
      statsD.dispose()
    }

    statsD.increment("mybucket")

    waitForExpectationsWithTimeout(10) { error in
      if let error = error {
        print("Error: \(error.localizedDescription)")
      }
    }
  }
  #else
    // temporarily removed on OSX while language features missing
    func testEmptiesBucketAfterSend() {}
    func testSendsDataAfterInterval() {}
    func testTimerShouldSetCorrectBuffer() {}
    func testDoesCallbackWithParametersAfterSend() {}
  #endif
}

extension StatsDTests {
    static var allTests: [(String, StatsDTests -> () throws -> Void)] {
        return [
          ("testConvenienceInitSetsCorrectValues", testConvenienceInitSetsCorrectValues),
          ("testInitSetsCorrectValues", testInitSetsCorrectValues),
          ("testIncrementShouldIncreaseBufferByOne", testIncrementShouldIncreaseBufferByOne),
          ("testIncrementTwiceShouldIncreaseBufferByTwo", testIncrementTwiceShouldIncreaseBufferByTwo),
          ("testIncrementShouldSetCorrectBuffer", testIncrementShouldSetCorrectBuffer),
          ("testTimerShouldIncreaseBufferByOne", testTimerShouldIncreaseBufferByOne),
          ("testTimerShouldSetCorrectBuffer", testTimerShouldSetCorrectBuffer),
          ("testGaugeShouldSetCorrectBuffer", testGaugeShouldSetCorrectBuffer),
          ("testSendsDataAfterInterval", testSendsDataAfterInterval),
          ("testEmptiesBucketAfterSend", testEmptiesBucketAfterSend),
          ("testDoesCallbackWithParametersAfterSend", testDoesCallbackWithParametersAfterSend)
        ]
    }
}
