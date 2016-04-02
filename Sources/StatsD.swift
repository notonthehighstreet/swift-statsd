import Foundation

public class StatsD
{

  var host:String
  var port:Int
  var socket:Socket
  var sendCallback:(() -> Void)?
  var buffer = [String]()
  var timer:NSTimer?

  // optional sendCallback is a closure which is called whenever the class sends data to the statsD server
  // can be used for testing or logging.
  init(host:String, port:Int, socket: Socket, sendCallback: (() -> Void)? = nil) {
    self.socket = socket
    self.port = port
    self.host = host
    self.sendCallback = sendCallback

    self.timer = NSTimer.scheduledTimer(1, repeats: true) { (timer: NSTimer) -> Void in
      self.sendBuffer()
    }
  }

  // Must be called when finished with the client or the timer will never shut down
  public func dispose() {
    self.timer!.invalidate()
  }

  public func increment(bucket:String) {
    //format [bucket]:[count]|c
    buffer.append("\(bucket):1|c")
  }

  public func timer(bucket:String, closure: (() -> Void)) {
    // format [bucket]:[duration]|ms

    let startTime = NSDate()
    closure()
    let endTime = NSDate()

    let duration = endTime.timeIntervalSinceDate(startTime) / 1000
    buffer.append("\(bucket):\(duration)|ms")
  }

  // This is not the most efficient way to do this, multiple counts can be concatonated and sent
  private func sendBuffer() {
    for data in buffer {
      send(data)
    }

    buffer = [String]()

    if sendCallback != nil {
      sendCallback!()
    }
  }

  private func send(data:String) {
    socket.write(host, port:port, data:data)
  }
}
