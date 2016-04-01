import Foundation
import XCTest

@testable import StatsD

class ConnectionTests: XCTestCase {
  func testConnect() {
    let connection = Connection()
    connection.connect()
    connection.senddata("deploys.test.balls:1|c")
    //XCTAssertEqual(1, 1, "Message shown when assert fails")
    //XCTAssertNil(nil, "Message shown when assert fails")
  }
}

extension ConnectionTests {
    static var allTests: [(String, ConnectionTests -> () throws -> Void)] {
        return [
            ("testConnect", testConnect),
        ]
    }
}
