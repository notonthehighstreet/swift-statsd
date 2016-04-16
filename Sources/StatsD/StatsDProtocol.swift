public protocol StatsDProtocol {
  /**
    dispose stops sending statistics
  */
  func dispose()

  /**
    increment increases the given bucket by 1
    format [bucket]:[count]|c

    - Parameters:
      - bucket: the stats bucket to increment the counter for
  */
  func increment(bucket:String)

  /**
    timer allows you to measure the execution time of a block of code and send this data to the bucket
    format [bucket]:[duration]|ms

    - Parameters:
      - bucket: the stats bucket to set the timer for
      - closure: the execution time is measured from the passed closure

    ```
      statsD.timer(bucket: "mybucket", closure: {
        for i in 0...1000 {
          // some code
        }
      })
    ```
  */
  func timer(bucket:String, closure: (() -> Void))

  /**
    gauge allows recording arbitrary values for the given metric
    format [metric]:[value]|g

    - Parameters:
      - metric: the name of the metric to set the gauge
      - value: the value to set for the gauge

  */
  func gauge(metric:String, value:Int32)
}
