# Introduction
Swift statsD is a statsD client implementation for swift.

Due to the incomplete nature of the current Foundation framework on Linux we have implemented a simple UDP socket class using libC.  Currently this library only supports IPV4 and UDP connectivity to a statsD server.  

For more information on libC sockets please see: http://www.gnu.org/software/libc/manual/html_node/Datagrams.html#Datagrams

# Build Instructions:
## Linux

### Start docker container
```bash
$ docker run --rm -i -t -p 8090:8090 -v $(pwd):/src -w /src ibmcom/kitura-ubuntu:latest /bin/bash  
```  

### Build and run tests
```bash
$ make test
```

## Mac
### Install Swiftenv
https://github.com/kylef/swiftenv

### Install 3.0 Alpha
```bash
$ swiftenv install DEVELOPMENT-SNAPSHOT-2016-03-24-a
$ swiftenv rehash
```

### Build and run tests
```bash
$ make test
```

## Example usage
Create an instance of the statsD collector
```swift
let socket = UDPSocket()
let statsd = StatsD(host: 127.0.0.1, port: 8125, socket, UDPSocket(), sendCallback: {
  // this block will execute every time data is sent to the server, this is an optional block.
})
```

Send a simple counter
```swift
statsd.increment("mybucket.name")
```

Time a block of code
```swift
statsd.timer("mybucket", closure: {
  for i in 0...10 {
    // do some stuff
  }
})
```

## statsD info
https://github.com/etsy/statsd

## Starting statsD server
```
$ docker run -p 8080:80 -p 8125:8125/udp -d hopsoft/graphite-statsd
```
Once started the interface to see posted metrics can been accessed at http://DOCKER_IP:8080.

## TODO
- Implement:
  - Sets
  - ~~Gauges~~
  - Sampling
- Implement updated socket which supports IPV6 and TCP
- Set build on CI
