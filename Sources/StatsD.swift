import Foundation

public class StatsD
{

  var host:String
  var port:Int
  var socket:Socket
  var sendCallback:(() -> Void)?
  var buffer = [String]()
  var timer:NSTimer?

  // implement locking for thread safety
  var bufferLock = NSLock()
  var sendLock = NSLock()

  // optional sendCallback is a closure which is called whenever the class sends data to the statsD server
  // can be used for testing or logging.
  init(host:String, port:Int, socket: Socket, sendCallback: (() -> Void)? = nil) {
    self.socket = socket
    self.port = port
    self.host = host
    self.sendCallback = sendCallback

    #if os(Linux)
    self.timer = NSTimer.scheduledTimer(1, repeats: true) { (timer: NSTimer) -> Void in
      self.sendBuffer()
    }
    #else
    self.timer = NSTimer(timeInterval: 1, target: self, selector: #selector(self.sendBuffer), userInfo: true, repeats: false)
    #endif
  }

  // Must be called when finished with the client or the timer will never shut down
  public func dispose() {
    self.timer!.invalidate()
  }

  /**
    increment increases the given bucket by 1
    format [bucket]:[count]|c

    - Parameters:
      - bucket: the stats bucket to increment the counter for
  */
  public func increment(bucket:String) {
    bufferLock.lock()
    defer {
      bufferLock.unlock()
    }

    buffer.append("\(bucket):1|c")
  }

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
  public func timer(bucket:String, closure: (() -> Void)) {
    let startTime = NSDate().timeIntervalSince1970
    closure()
    let endTime = NSDate().timeIntervalSince1970

    let duration = (endTime - startTime) / 1000

    bufferLock.lock()
    defer {
      bufferLock.unlock()
    }
    buffer.append("\(bucket):\(duration)|ms")
  }

  /**
    gauge allows recording arbitrary values for the given metric
    format [metric]:[value]|g

    - Parameters:
      - metric: the name of the metric to set the gauge
      - value: the value to set for the gauge

  */
  func gauge(metric:String, value:Int32) {
    bufferLock.lock()
    defer {
      bufferLock.unlock()
    }

    buffer.append("\(metric):\(value)|g")
  }

  // This is not the most efficient way to do this, multiple counts can be concatonated and sent
  @objc
  private func sendBuffer() {
    bufferLock.lock()
    if buffer.count < 1 {
      bufferLock.unlock()
      return
    }
    var sendBuffer = buffer // copy the send data to reduce blocking on send
    buffer = [String]() // clear buffer
    bufferLock.unlock()

    sendLock.lock()
    defer {
      sendLock.unlock()
    }

    for data in sendBuffer {
      send(data)
    }

    if sendCallback != nil {
      sendCallback!()
    }
  }

  private func send(data:String) {
    socket.write(host, port:port, data:data)
  }
}
