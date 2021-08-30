# gRPC 'helloworld' SwiftUI client with Combine

<img width="200" src="https://github.com/itsjohnye/grpc-helloworld-swiftui-client/blob/main/ScreenShot.png"/>

The project shows the gRPC *helloworld* example with **iOS client** and **golang server**.
The server part is referenced from offical gRPC site: [gRPC Go quickstart](https://grpc.io/docs/languages/go/quickstart/).

## Logistics

#### Run the server

```shell
cd greeter-server
go mod tidy
go run main.go
```

#### And then run the SwiftUIClient XCode Project.



## Notes

Using identical `.proto` file in both server and client side, if you want to run *helloworld*  in other gRPC supported language:

```protobuf
// helloworld.proto
syntax = "proto3";
option go_package = "google.golang.org/grpc/examples/helloworld/helloworld";
option java_multiple_files = true;
option java_package = "io.grpc.examples.helloworld";
option java_outer_classname = "HelloWorldProto";

package helloworld;

// The greeting service definition.
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
}

// The request message containing the user's name.
message HelloRequest {
  string name = 1;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
} 
```

#### Server-side Protocol Buffer generation:

```shell
cd greeter-server
protoc --go_out=. --go_opt=paths=source_relative \
    --go-grpc_out=. --go-grpc_opt=paths=source_relative \
    proto/helloworld.proto
```

#### Client-side Protocol Buffer generation:

```shell
cd proto
protoc --grpc-swift_out=Client=true,Server=false:. \
    --swift_out=. \
    helloworld.proto
```

Dragge and droppe files `helloworld.pb.swift` and `helloworld.grpc.swift` which were generated by command line `protoc`  into the client-side project.

Swift Package Manager has already added the package dependency [gRPC-Swift](https://github.com/grpc/grpc-swift).

Notably, we use ` localhost:50051` in this example.



## License
[WTFPL](https://github.com/itsjohnye/grpc-helloworld-swiftui-client/blob/main/LICENSE)
