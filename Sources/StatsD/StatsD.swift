import Foundation
import Dispatch

public class StatsD: StatsDProtocol
{

  var host:String
  var port:Int
  var socket:Socket
  var sendCallback:((Bool, SocketError?) -> Void)?

  let queue:DispatchQueue 
  var running = false
  let sendInterval: Double

  var buffer = [String]()

  // implement locking for thread safety
  var bufferLock = NSLock()
  var sendLock = NSLock()

  /**
    class initialiser

    - Parameters:
      - host: ip address or fqdn of the StatsD server
      - port: udp port number for the StatsD server
      - socket: socket communication instance
      - sendCallback: optional closure which is fired everytime statistics are sent to the server, this block contains a boolean
      for the outcome for sending data and an error object.  In the instance of being unable to open a socket to the server
      false and an error will be returned.  Because we are sending a UDP packet we will not get any response from the server
      in the instance of a malformed request or server malfunction.

      ```
        let statsD = StatsD("127.0.0.1", port: 8125, socket: UDPSocket(),
          sendCallback: {(success: Bool, error: SocketError?) in
            print("Sent data to server")
          }
        )
      ```
  */
  public convenience init(host:String, port:Int, socket: Socket, sendCallback: ((Bool, SocketError?) -> Void)? = nil) {
    self.init (host: host, port: port, socket: socket, interval: 1, sendCallback: sendCallback)
  }

  /**
    class initialiser

    - Parameters:
      - host: ip address or fqdn of the StatsD server
      - port: udp port number for the StatsD server
      - socket: socket communication instance
      - interval: set the interval that data is sent to the server
      - sendCallback: optional closure which is fired everytime statistics are sent to the server, this block contains a boolean
      for the outcome for sending data and an error object.  In the instance of being unable to open a socket to the server
      false and an error will be returned.  Because we are sending a UDP packet we will not get any response from the server
      in the instance of a malformed request or server malfunction.

      ```
        let statsD = StatsD("127.0.0.1", port: 8125, socket: UDPSocket(),
          sendCallback: {(success: Bool, error: SocketError?) in
            print("Sent data to server")
          }
        )
      ```
  */
  public init(host:String, port:Int, socket: Socket, interval: Double, sendCallback: ((Bool, SocketError?) -> Void)? = nil) {
    self.socket = socket
    self.port = port
    self.host = host
    self.sendCallback = sendCallback
    self.sendInterval = interval

    self.running = true

    queue = DispatchQueue(label: "com.notonthehighstreet.statsd." + String(NSDate().timeIntervalSince1970))
    sendLoop(interval: self.sendInterval)
  }

  /**
    dispose stops sending statistics and allows the object to be garbage collected, if this method is not called then the timer
    will not invalidate and will continue for the life of the program.
  */
  public func dispose() {
    running = false;
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
  public func gauge(metric:String, value:Int32) {
    bufferLock.lock()
    defer {
      bufferLock.unlock()
    }

    buffer.append("\(metric):\(value)|g")
  }

  private func sendLoop(interval: Double) {
    let delay = DispatchTime.now() + interval
    self.queue.asyncAfter(deadline: delay, qos: .default, flags: DispatchWorkItemFlags()) {
      if(self.running) {
        self.sendBuffer() // send any data in the buffer
        self.sendLoop(interval: interval) // restart the timer
      }
    }
  }

  // This is not the most efficient way to do this, multiple counts can be concatonated and sent
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
      send(data: data)
    }
  }

  private func send(data:String) {
    let (success, error) = socket.write(host: host, port:port, data:data)
    if sendCallback != nil {
      sendCallback!(success, error)
    }
  }
}
