import SwiftUI
import GRPC
import NIO

struct ContentView: View {
    
    @State private var helloText = ""
    @State private var name = ""
    var body: some View {
    
        VStack {
            Text("\(helloText)").border(Color.black, width: 1).foregroundColor(.blue)
            
            Button(action: greeting){
                Text("get response").foregroundColor(.white)
            }.padding().background(Color.blue).padding()
            
            HStack{
                Text("Name: ")
                
                TextField(
                    "Input your name here",
                     text: $name)
            }.padding()
        }
    }
    
    func greeting(){
        let port: Int = 50051
        let name: String = name
        // See: https://github.com/apple/swift-nio#eventloops-and-eventloopgroups
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        // Make sure the group is shutdown when we're done with it.
        defer {
            try! group.syncShutdownGracefully()
        }
        // Configure the channel, we're not using TLS so the connection is `insecure`.
        let channel = ClientConnection.insecure(group: group)
            .connect(host: "localhost", port: port)
        // Close the connection when we're done with it.
        defer {
            try! channel.close().wait()
        }
        // Provide the connection to the generated client.
        let greeter = Helloworld_GreeterClient(channel: channel)
        // Do the greeting.
        let request = Helloworld_HelloRequest.with {
            $0.name = name
        }
        
        // Make the RPC call to the server.
        let sayHello = greeter.sayHello(request)
        
        // wait() on the response to stop the program from exiting before the response is received.
        do {
            let response = try sayHello.response.wait()
            helloText = response.message
            print("Greeter received: \(response.message)")
        } catch {
            print("Greeter failed: \(error)")
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
