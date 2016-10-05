import XCTest

@testable import StatsDTests

XCTMain([
  testCase(StatsDTests.allTests),
  testCase(UDPSocketTests.allTests)
])
