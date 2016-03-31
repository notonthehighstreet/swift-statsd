import Foundation
import XCTest

class StatsDTests: XCTestCase {
  var allTests : [(String, () throws -> Void)] {
    return [
      ("testAsserts", testAsserts)
    ]
  }

  func testAsserts() {
    XCTAssertEqual(1, 1, "Message shown when assert fails")
    XCTAssertNil(nil, "Message shown when assert fails")
    //XCTFail("Message always shows since this always fails")
  }
}
