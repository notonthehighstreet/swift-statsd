import Foundation

public class StatsD
{

  var host:String
  var port:Int
  var socket:Socket
  var sendCallback:(() -> Void)?
  var counters = [String: Int32]()
  var timer:NSTimer?

  // optional sendCallback is a closure which is called whenever the class sends data to the statsD server
  // can be used for testing or logging.
  init(host:String, port:Int, socket: Socket, sendCallback: (() -> Void)? = nil) {
    self.socket = socket
    self.port = port
    self.host = host
    self.sendCallback = sendCallback

    self.timer = NSTimer.scheduledTimer(1, repeats: true) { (timer: NSTimer) -> Void in
      self.sendCounters()
    }
  }

  // Must be called when finished with the client or the timer will never shut down
  public func dispose() {
    self.timer!.invalidate()
  }

  public func increment(bucket:String) {
    if counters[bucket] != nil {
      counters[bucket]! += 1
    } else {
      counters[bucket] = 1
    }
  }

  // This is not the most efficient way to do this, multiple counts can be concatonated and sent
  private func sendCounters() {
    for (bucket, count) in counters {
      //format [bucket]:[count]|c
      let data = bucket + ":" + String(count) + "|c"
      send(data)
    }

    counters = [String: Int32]()

    if sendCallback != nil {
      sendCallback!()
    }
  }

  private func send(data:String) {
    socket.write(host, port:port, data:data)
  }
}
