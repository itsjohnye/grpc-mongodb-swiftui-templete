//
//  StreamingViewModel.swift
//  Storage
//
//  Created by John Ye on 2022/7/20.
//

import SwiftUI
import GRPC
import Combine
import NIO
import NIOHPACK

@MainActor
final class ServerStreamService: ObservableObject {
    @AppStorage("useruuid") var uuid: String = ""
    @AppStorage("isInServerStreaming") var isInServerStreaming: Bool = false
    @Published var message = ""
    @Published var isSubscribed = false
    @Published var isPopupPresented = false
    @Published var responsesFromServer = ""
    //Popup alert/message/diagrame
    enum PopupState {
        case gRPCError(String)
    }
    @Published var popupState: PopupState?
    
    //gRPC streaming call
    private let asyncClient = GRPCClientStub.shared.asyncClient
    private var subscribtionCall: GRPCAsyncServerStreamingCall<Storage_SubscribeRequest, Storage_ServerStreamResponse>? = nil
    // let callOptions = CallOptions(timeLimit: .timeout(.seconds(3)))
    
    init(){
        print("ServerStreamService init()")
    }
    
    func broadcast() {
        print("ServerStreamService - broadcast()")
        
        let req: Storage_Greeting = .with{
            $0.userUuid = self.uuid
            $0.message = self.message
        }
        Task{
            do{
                _ = try await self.asyncClient.broadcast(req)
            } catch {
                print(error)
                self.popupState = .gRPCError("\(error)")
                self.isPopupPresented = true
            }
        }
        
    }
    
    func subscribe(closure: @escaping () async throws -> Void) {
        print("ServerStreamService - subscribe()")
        let req: Storage_SubscribeRequest = .with{
            $0.userUuid = self.uuid
        }
        self.subscribtionCall = asyncClient.makeSubscribeCall(req)
        self.isInServerStreaming = true
        
        Task{
            do{
                try await withThrowingTaskGroup(of: Void.self) { group in
                    // group1
                    group.addTask {
                        for try await res in await self.subscribtionCall!.responseStream {
                            print("Received: \(res.broadcastMessage)")
                            DispatchQueue.main.async {
                                self.responsesFromServer = res.broadcastMessage
                                self.isSubscribed = true
                            }
                        }
                    }
                    // group2
                    group.addTask {
                        try await closure()
                    }
                    try await group.waitForAll()
                }
            } catch (let error) {
                if let err: GRPCStatus = error as? GRPCStatus {
                    if err.code == .unavailable {       //handle different errors
                        print("error ignore X")
                    } else {
                        self.popupState = .gRPCError("\(err)")
                        self.isPopupPresented = true
                    }
                }
            }
        }
    }
    
    func unsubscribe() {
        print("ServerStreamService - unsubscribe()")
        let req: Storage_UnsubscribeRequest = .with{
            $0.userUuid = self.uuid
        }
        
        Task{
            do{
                let resp = try await self.asyncClient.unsubscribe(req)
                print(resp)
                self.subscribtionCall = nil
                self.isSubscribed = false
                self.isInServerStreaming = false
            } catch {
                print(error)
                self.popupState = .gRPCError("\(error)")
                self.isPopupPresented = true
            }
        }
    }
    
}
