public protocol StatsDProtocol {
  /**
    dispose stops sending statistics and allows the object to be garbage collectable
  */
  func dispose()

  /**
    increment increases the given bucket by 1

    - Parameters:
      - bucket: the stats bucket to increment the counter for
  */
  func increment(bucket:String)

  /**
    timer allows you to measure the execution time of a block of code and send this data to the bucket

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
}
