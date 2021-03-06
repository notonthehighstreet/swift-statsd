#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

import Foundation

public class UDPSocket: Socket
{
  public static let SOCKET_INVALID_DESCRIPTOR = Int32(-1)
  public static let IPV4 = Int32(AF_INET)
  public static let UDP = Int32(IPPROTO_UDP)

  #if os(Linux)
  public static let DGRAM = Int32(SOCK_DGRAM.rawValue)
  #else
  public static let DGRAM = Int32(SOCK_DGRAM)
  #endif

  var socketfd: Int32 = SOCKET_INVALID_DESCRIPTOR

  public init() {}

  internal func createSocket() throws -> Void{
    #if os(Linux)
		   self.socketfd = Glibc.socket(UDPSocket.IPV4, UDPSocket.DGRAM, UDPSocket.UDP)
	  #else
		   self.socketfd = Darwin.socket(UDPSocket.IPV4, UDPSocket.DGRAM, UDPSocket.UDP)
	  #endif

		// If error, throw an appropriate exception...
		if self.socketfd < 0 {
			self.socketfd = UDPSocket.SOCKET_INVALID_DESCRIPTOR
      throw SocketError.UnableToCreateSocket
		}
  }

  internal func setAddressInfo(host: String, port: Int) throws -> UnsafeMutablePointer<addrinfo>? {
    #if os(Linux)
			var hints = addrinfo(
				ai_flags: AI_PASSIVE,
				ai_family: AF_UNSPEC,
				ai_socktype: UDPSocket.DGRAM,
				ai_protocol: 0,
				ai_addrlen: 0,
				ai_addr: nil,
				ai_canonname: nil,
				ai_next: nil)
		#else
			var hints = addrinfo(
				ai_flags: AI_PASSIVE,
				ai_family: AF_UNSPEC,
				ai_socktype: UDPSocket.DGRAM,
				ai_protocol: 0,
				ai_addrlen: 0,
				ai_canonname: nil,
				ai_addr: nil,
				ai_next: nil)
		#endif

		// Retrieve the info on our target...
    var targetInfo: UnsafeMutablePointer<addrinfo>? = UnsafeMutablePointer<addrinfo>.allocate(capacity: 1)
		let status: Int32 = getaddrinfo(host, String(port), &hints, &targetInfo)

    if status != 0 {
      throw SocketError.FailedToResolveAddress
    }

    return targetInfo
  }

  internal func sendData(data: String, targetInfo: UnsafeMutablePointer<addrinfo>) throws -> Void {
    var sendFlags: Int32 = 0
    var size:Int = 0

    data.utf8CString.withUnsafeBufferPointer() {
			// The count returned by nullTerminatedUTF8 includes the null terminator...
      #if os(Linux)
  		  size = Glibc.sendto(
          self.socketfd,
          $0.baseAddress,
          $0.count-1,
          sendFlags,
          targetInfo.pointee.ai_addr,
          targetInfo.pointee.ai_addrlen)
  	  #else
  		  size = Darwin.sendto(
           self.socketfd,
           $0.baseAddress,
           $0.count-1,
           sendFlags,
           targetInfo.pointee.ai_addr,
           targetInfo.pointee.ai_addrlen)
  	  #endif
		}

    if size <= 0 {
      throw SocketError.FailedToSendData
    }
  }

  internal func close() {
    if self.socketfd != UDPSocket.SOCKET_INVALID_DESCRIPTOR {
      #if os(Linux)
		    _ = Glibc.close(self.socketfd)
		  #else
			  _ = Darwin.close(self.socketfd)
		  #endif
    }

		self.socketfd = UDPSocket.SOCKET_INVALID_DESCRIPTOR
  }
}

extension UDPSocket {
  public func write(host: String, port: Int, data: String) -> (Bool, SocketError?){
    do {
      try self.createSocket()
      defer {
        close()
      }

      var targetInfo = try setAddressInfo(host: host, port: port)
      defer {
  			if targetInfo != nil {
  				freeaddrinfo(targetInfo)
  			}
  		}

      try sendData(data: data, targetInfo: targetInfo!)

      return (true, nil)
    } catch {
      return (false, error as? SocketError)
    }
  }
}
