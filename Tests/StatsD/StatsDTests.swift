import Foundation
import XCTest

class StatsDTests: XCTestCase {
  func testAsserts() {
    XCTAssertEqual(1, 1, "Message shown when assert fails")
    XCTAssertNil(nil, "Message shown when assert fails")
    //XCTFail("Message always shows since this always fails")
  }
}

extension StatsDTests {
    static var allTests: [(String, StatsDTests -> () throws -> Void)] {
        return [
            ("testAsserts", testAsserts),
        ]
    }
}
