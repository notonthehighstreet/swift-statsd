import XCTest

@testable import StatsDTestSuite

XCTMain([
  testCase(StatsDTests.allTests),
  testCase(UDPSocketTests.allTests)
])
