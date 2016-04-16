import Foundation
import StatsD

print("Test StatsD send")

let statsD = StatsD(host: "docker.local", port: 8125, socket: UDPSocket(), interval: 1,
  sendCallback: { (success: Bool, error: SocketError?) in
    print("sdsdsd")
  }
)

while (true) {
  print("send data")
  statsD.increment("dfdfdfdf")
  sleep(1)
}
