#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
    import Darwin
    import Foundation
    import Socket
#elseif os(Linux)
    import Glibc
    import Foundation
    import Socket
#endif

public class Connection
{
  public func connect() {
    print("Connecting to Server:")

    do {
      let signature = try Socket.Signature(
        socketType: Socket.SocketType.STREAM,
        proto: Socket.SocketProtocol.UDP,
        hostname: "127.0.0.1",
        port: 8125
      )

      let socket = try Socket.makeConnected(using: signature!)
    } catch let e {
      print(e)
    }
  }
}
