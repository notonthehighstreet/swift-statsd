import Foundation
import XCTest

@testable import StatsD

class ConnectionTests: XCTestCase {
  var allTests : [(String, () throws -> Void)] {
    return [
      ("testConnect", testConnect)
    ]
  }

  func testConnect() {
    let connection = Connection()
    connection.connect()
    //XCTAssertEqual(1, 1, "Message shown when assert fails")
    //XCTAssertNil(nil, "Message shown when assert fails")
  }
}
