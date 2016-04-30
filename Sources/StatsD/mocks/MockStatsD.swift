import Foundation

// MockStatsD is a mock implementation of the statsDprotocl which can be used with your tests
public class MockStatsD: StatsDProtocol {
  var timerCalled = false
  var timerBucket: String?

  var incrementCalled = false
  var incrementBucket: String?

  public func dispose() {}
  public func increment(bucket:String) {
    incrementCalled = true
    incrementBucket = bucket
  }

  public func timer(bucket:String, closure: (() -> Void)) {
    timerCalled = true
    timerBucket = bucket
    closure()
  }

  public func gauge(metric:String, value:Int32) {}
}
