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
    
    static let shared = GRPCClientStub()    //use Singleton
    
    private let group = PlatformSupport.makeEventLoopGroup(loopCount: 1)
    
    var client: Storage_StorageNIOClient
    
    private init() {
        print("init GRPCClientStub")
        let channel = try! GRPCChannelPool.with(
            target: .host("localhost", port: 50051),
            transportSecurity: .plaintext,      //MARK: if TLS, see https://github.com/grpc/grpc-swift/blob/main/docs/tls.md
            eventLoopGroup: group
        )
        self.client = Storage_StorageNIOClient(channel: channel)
    }
    
    deinit {
        print("deinit GRPCClientStub")
        do {
            try client.channel.close().wait()
            try group.syncShutdownGracefully()
        } catch {
            print(error)
        }
    }
    
}





