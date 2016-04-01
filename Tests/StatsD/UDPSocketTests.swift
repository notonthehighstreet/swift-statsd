import Foundation
import XCTest

@testable import StatsD

class UDPSocketTests: XCTestCase {
  func testSocket() {
    let socket = UDPSocket()
    let result = socket.write("192.168.99.100", port: 8125, data: "deploys.test.balls:1|c")
    //XCTAssertEqual(1, 1, "Message shown when assert fails")
    XCTAssertNil(result.1, "Write shoud not have returned an error")
  }
}

extension UDPSocketTests {
    static var allTests: [(String, UDPSocketTests -> () throws -> Void)] {
        return [
            ("testSocket", testSocket),
        ]
    }
}
