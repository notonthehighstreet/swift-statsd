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

    statsD.increment(bucket: "mybucket")

    XCTAssertEqual(1, statsD.buffer.count, "Buffer should container 1 item")
  }

  func testIncrementTwiceShouldIncreaseBufferByTwo() {
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: MockSocket())
    defer {
      statsD.dispose()
    }

    statsD.increment(bucket: "mybucket")
    statsD.increment(bucket: "mybucket")

    XCTAssertEqual(2, statsD.buffer.count, "Buffer should container 2 items")
  }

  func testIncrementShouldSetCorrectBuffer() {
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: MockSocket())
    defer {
      statsD.dispose()
    }

    statsD.increment(bucket: "mybucket")

    XCTAssertEqual("mybucket:1|c", statsD.buffer[0], "Buffer should contain correct value")
  }

  func testTimerShouldIncreaseBufferByOne() {
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: MockSocket())
    defer {
      statsD.dispose()
    }

    statsD.timer(bucket: "mybucket") {
      print("Setting Timer")
    }

    XCTAssertEqual(1, statsD.buffer.count, "Buffer should container 1 items")
  }

  func testGaugeShouldSetCorrectBuffer() {
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: MockSocket())
    defer {
      statsD.dispose()
    }

    statsD.gauge(metric: "mybucket", value: 333)

    XCTAssertEqual("mybucket:333|g", statsD.buffer[0], "Buffer should contain correct value")
  }

  func testTimerShouldSetCorrectBuffer() {
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: MockSocket())
    defer {
      statsD.dispose()
    }

    statsD.timer(bucket: "mybucket") {
      print("Setting Timer")
    }


    let buffer = statsD.buffer[0]
    let bucket = buffer.characters.split(separator: ":").map{ String($0) }[0]
    let duration = buffer.characters.split(separator: ":").map{ String($0) }[1].characters.split(separator: "|").map{ String($0) }[0]

    XCTAssertEqual("mybucket", bucket, "Buffer should contain bucket")
    XCTAssertTrue(Float(duration)! > 0.0, "Buffer should contain duration")
  }

  func testSendsDataAfterInterval() {
    let mockSocket = MockSocket()
    let ex = expectation(description: "Send data after interval")

    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: mockSocket, interval: 0.1) {
      (success: Bool, error: SocketError?) in
        XCTAssertEqual(1, mockSocket.timesWritten, "Expected to have called write")
        ex.fulfill()
    }

    defer {
      statsD.dispose()
    }

    statsD.increment(bucket: "mybucket")

    waitForExpectations(timeout: 3) { error in
      if let error = error {
        print("Error: \(error.localizedDescription)")
      }
    }
  }

  func testSendsDataMultipleTimesAfterInterval() {
    let mockSocket = MockSocket()
    let ex = expectation(description: "Send data multiple times after interval")

    var statsD: StatsD? = nil
    statsD = StatsD(host: "192.168.99.100", port: 8125, socket: mockSocket, interval: 0.1) {
      (success: Bool, error: SocketError?) in
        if mockSocket.timesWritten < 3 {
          statsD!.increment(bucket: "mybucket")
        } else {
          XCTAssertEqual(3, mockSocket.timesWritten, "Expected to have called write 3 times")
          ex.fulfill()
        }
    }

    defer {
      statsD!.dispose()
    }

    statsD!.increment(bucket: "mybucket")

    waitForExpectations(timeout: 20) { error in
      if let error = error {
        print("Error: \(error.localizedDescription)")
      }
    }
  }

  func testDisposeStopsSendingData() {
    let mockSocket = MockSocket()
    let ex = expectation(description: "Send data after interval")

    var statsD: StatsD? = nil
    statsD = StatsD(host: "192.168.99.100", port: 8125, socket: mockSocket, interval: 0.1) {
      (success: Bool, error: SocketError?) in
        statsD!.dispose()
        statsD!.increment(bucket: "mybucket")
        ex.fulfill()
    }

    statsD!.increment(bucket: "mybucket")

    waitForExpectations(timeout: 20) { error in
      if let error = error {
        print("Error: \(error.localizedDescription)")
      }
    }

    usleep(200) // wait to see that a second send has not been called

    XCTAssertEqual(1, mockSocket.timesWritten, "Expected to have called write 1 times")
  }

  func testEmptiesBucketAfterSend() {
    let ex = expectation(description: "Empty bucket after send")
    var statsD: StatsD?
    statsD = StatsD(host: "192.168.99.100", port: 8125, socket: MockSocket(), interval: 0.1) {
      (success: Bool, error: SocketError?) in
        XCTAssertEqual(0, statsD!.buffer.count, "Expected to have emptied bucket")
        ex.fulfill()
    }

    defer {
      statsD!.dispose()
    }

    statsD!.increment(bucket: "mybucket")

    waitForExpectations(timeout: 20) { error in
      if let error = error {
        print("Error: \(error.localizedDescription)")
      }
    }
  }

  func testDoesCallbackWithParametersAfterSend() {
    let mockSocket = MockSocket()
    let ex = expectation(description: "Send data after interval")
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: mockSocket, interval: 0.1) {
      (success: Bool, error: SocketError?) in
        XCTAssertTrue(success, "Expected to have returned success on callback")
        XCTAssertNotNil(error, "Expected to have returned error on callback")
        ex.fulfill()
    }

    defer {
      statsD.dispose()
    }

    statsD.increment(bucket: "mybucket")

    waitForExpectations(timeout: 10) { error in
      if let error = error {
        print("Error: \(error.localizedDescription)")
      }
    }
  }
}

extension StatsDTests {
    static var allTests: [(String, (StatsDTests) -> () throws -> Void)] {
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
          ("testSendsDataMultipleTimesAfterInterval", testSendsDataMultipleTimesAfterInterval),
          ("testDisposeStopsSendingData", testDisposeStopsSendingData),
          ("testEmptiesBucketAfterSend", testEmptiesBucketAfterSend),
          ("testDoesCallbackWithParametersAfterSend", testDoesCallbackWithParametersAfterSend)
        ]
    }
}
