#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

import Foundation

public class Connection
{
  public static let SOCKET_INVALID_DESCRIPTOR = Int32(-1)

  var socketfd: Int32 = SOCKET_INVALID_DESCRIPTOR

  public func connect() {
    print("Connecting to Server:")

    let ipv4 = Int32(AF_INET)
    let dgram = Int32(SOCK_DGRAM.rawValue)
    let udp = Int32(IPPROTO_UDP)

    #if os(Linux)
		   self.socketfd = Glibc.socket(ipv4, dgram, udp)
	  #else
		   self.socketfd = Darwin.socket(ipv4, dgram, udp)
	  #endif

		// If error, throw an appropriate exception...
		if self.socketfd < 0 {
			self.socketfd = Connection.SOCKET_INVALID_DESCRIPTOR
      print("unable to create socket")
		}

    print("created socket")
  }

  public func senddata(data: String) {
    print("sending data" + data)

    let host = "192.168.99.100"
    let port = 8125

    #if os(Linux)
			var hints = addrinfo(
				ai_flags: AI_PASSIVE,
				ai_family: AF_UNSPEC,
				ai_socktype: Int32(SOCK_DGRAM.rawValue),
				ai_protocol: 0,
				ai_addrlen: 0,
				ai_addr: nil,
				ai_canonname: nil,
				ai_next: nil)
		#else
			var hints = addrinfo(
				ai_flags: AI_PASSIVE,
				ai_family: AF_UNSPEC,
				ai_socktype: Int32(SOCK_DGRAM.rawValue),
				ai_protocol: 0,
				ai_addrlen: 0,
				ai_canonname: nil,
				ai_addr: nil,
				ai_next: nil)
		#endif

		var targetInfo = UnsafeMutablePointer<addrinfo>(allocatingCapacity: 1)

		// Retrieve the info on our target...
		let status: Int32 = getaddrinfo(host, String(port), &hints, &targetInfo)

    if status != 0 {
      print("failed to lookup socket")
    }

    var sendFlags: Int32 = 0

    data.nulTerminatedUTF8.withUnsafeBufferPointer() {
			// The count returned by nullTerminatedUTF8 includes the null terminator...
      #if os(Linux)
  		   let size = Glibc.sendto(self.socketfd, $0.baseAddress, $0.count-1, sendFlags, targetInfo.pointee.ai_addr, targetInfo.pointee.ai_addrlen)
  	  #else
  		   let size = Darwin.sendto(self.socketfd, $0.baseAddress, $0.count-1, sendFlags, targetInfo.pointee.ai_addr, targetInfo.pointee.ai_addrlen)
  	  #endif

      if size <= 0 {
        print("failed to send")
      }

      print ("sent data")
		}
  }

}
