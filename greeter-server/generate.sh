# server
protoc --go_out=. --go_opt=paths=source_relative \
    --go-grpc_out=. --go-grpc_opt=paths=source_relative \
    proto/helloworld.proto

# client
cd proto
protoc --grpc-swift_out=Client=true,Server=false:. \
    --swift_out=. \
    helloworld.proto