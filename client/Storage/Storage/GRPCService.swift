//
//  GRPCService.swift
//  Storage
//
//  Created by John Ye on 2022/3/22.
//

import SwiftUI
import GRPC
import NIO

//This Stub theoretically runs through the entire program life-cycle
final class GRPCClientStub{
    static let shared = GRPCClientStub()
    
    private var group: EventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: 1)    //new offical sugeested method
    
    var client: Storage_StorageClient
    
    private init(){
        let channel = ClientConnection
            .insecure(group: group)
            .connect(host: "localhost", port: 50051)
        //.withConnectionReestablishment(enabled: true)
        
        
        self.client = Storage_StorageClient(channel: channel)
        //TODO: interceptor
        //TODO: TLS
        //see https://github.com/grpc/grpc-swift/blob/main/docs/tls.md
    }
    
    deinit {
        do {
            try client.channel.close().wait()
            try group.syncShutdownGracefully()
        } catch {
            print(error)
        }
    }
    
}
