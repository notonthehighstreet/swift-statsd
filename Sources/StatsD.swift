public class StatsD
{

  var host:String
  var port:Int
  var socket:Socket

  var counters = [String: Int32]()

  init(host:String, port:Int, socket: Socket) {
    self.socket = socket
    self.port = port
    self.host = host
  }

  public func increment(bucket:String) {
    //gorets:1|c
    if counters[bucket] != nil {
      counters[bucket]! += 1
    } else {
      counters[bucket] = 1
    }
  }

  // This is not the most efficient way to do this, multiple counts can be concatonated and sent
  private func sendCounters() {
    for (bucket, count) in counters {
      let data = bucket + ":" + String(count) + "|c"
      send(data)
    }
  }

  private func send(data:String) {
    socket.write(host, port:port, data:data)
  }
}
