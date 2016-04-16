public protocol Socket {
  func write(host: String, port: Int, data: String) -> (Bool, SocketError?)
}
