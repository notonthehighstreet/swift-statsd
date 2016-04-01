import Foundation
import XCTest

@testable import StatsD

class StatsDTests: XCTestCase {
  func testInitSetsCorrectValues() {
    let port = 8125
    let host = "127.0.0.1"
    let socket:Socket = UDPSocket()
    let statsD = StatsD(host: host, port: port, socket: socket)

    XCTAssertEqual(port, statsD.port, "Port should be equal")
    XCTAssertEqual(host, statsD.host, "Host should be equal")
    XCTAssertNotNil(statsD.socket, "Socket should not be nil")
  }

  func testIncrementShouldIncreaseBucketCountByOne() {
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: UDPSocket())
    statsD.increment("mybucket")

    XCTAssertEqual(1, statsD.counters["mybucket"], "Counter for mybucket should be 1")
  }

  func testIncrementTwiceShouldIncreaseBucketCountByTwo() {
    let statsD = StatsD(host: "192.168.99.100", port: 8125, socket: UDPSocket())
    statsD.increment("mybucket")
    statsD.increment("mybucket")

    XCTAssertEqual(2, statsD.counters["mybucket"], "Counter for mybucket should be 2")
  }
}

extension StatsDTests {
    static var allTests: [(String, StatsDTests -> () throws -> Void)] {
        return [
          ("testInitSetsCorrectValues", testInitSetsCorrectValues),
          ("testIncrementShouldIncreaseBucketCountByOne", testIncrementShouldIncreaseBucketCountByOne),
        ]
    }
}
