//
//  GRPCService.swift
//  Storage
//
//  Created by John Ye on 2022/6/23.
//

import SwiftUI
import GRPC
import NIO

//This Stub theoretically runs through the entire program life-cycle
final class GRPCClientStub{
    
    static let shared = GRPCClientStub()    //Singleton
    
    private let group = PlatformSupport.makeEventLoopGroup(loopCount: 1)
    
    var asyncClient: Storage_StorageAsyncClient     //Async method
    var nioClient: Storage_StorageNIOClient         //Nio method
    
    private init() {
        print("init GRPCClientStub")
        let channel = try! GRPCChannelPool.with(
            target: .host("localhost", port: 50051),
            transportSecurity: .plaintext,      //MARK: if TLS, see https://github.com/grpc/grpc-swift/blob/main/docs/tls.md
            eventLoopGroup: group
        )
        self.asyncClient = Storage_StorageAsyncClient(channel: channel)
        self.nioClient = Storage_StorageNIOClient(channel: channel)
    }
    
    deinit {
        print("deinit GRPCClientStub")
        do {
            try asyncClient.channel.close().wait()
            try nioClient.channel.close().wait()
            try group.syncShutdownGracefully()
        } catch {
            print(error)
        }
    }
    
}





