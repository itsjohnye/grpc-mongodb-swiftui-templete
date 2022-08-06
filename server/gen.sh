# "$chmod 755 gen.sh" first. "$./gen.sh" for execute.
# server
protoc --go_out=. --go_opt=paths=source_relative \
    --go-grpc_out=. --go-grpc_opt=paths=source_relative \
    proto/storage.proto


# Swift client, firstly path to 'proto' directory
cd proto
protoc --grpc-swift_out=Client=true,Server=false:. \
    --swift_out=. \
    storage.proto