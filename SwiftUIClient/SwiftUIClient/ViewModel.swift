//
//  ViewModel.swift
//  SwiftUIClient
//
//  Created by Yip on 2021/8/26.
//

import SwiftUI
import Combine
import GRPC
import NIO

final class ViewModel: ObservableObject {
    
    
    private var group: EventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: 1)    //new offical sugeested method
    
    private var client: Helloworld_GreeterClient
    
    init(){
        // Configure the channel, we're not using TLS so the connection is `insecure`.
        self.client = Helloworld_GreeterClient(channel: ClientConnection.insecure(group: group).connect(host: "localhost", port: 50051))
  
    }
    
    // Close the connection when we're done with it.
    deinit {
        do {
            try group.syncShutdownGracefully()
            try client.channel.close().wait()
        } catch {
            print(error)
        }

    }
    
    
    func greeting(name:String) -> AnyPublisher<Helloworld_HelloReply, Error>{

        Deferred {
            
            Future<Helloworld_HelloReply,Error> { promise in
                
                // Do the greeting.
                let request = Helloworld_HelloRequest.with {
                    $0.name = name
                }
                
                // Make the RPC call to the server.
                let call = self.client.sayHello(request)
                
                // wait() on the response to stop the program from exiting before the response is received.
                do {
                    let response = try call.response.wait()
                    promise(.success(response))
                } catch {
                    promise(.failure(error))
                }
            }
        }.subscribe(on: DispatchQueue.global())
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
}

