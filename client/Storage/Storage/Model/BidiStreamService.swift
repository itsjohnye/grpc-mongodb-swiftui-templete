//
//  BidiStreamService.swift
//  Storage
//
//  Created by John Ye on 2022/7/29.
//

import SwiftUI
import GRPC
import Combine

@MainActor
final class BidiStreamService: ObservableObject {
    @AppStorage("useruuid") var uuid: String = ""
    @AppStorage("isInBidiStreaming") var isInBidiStreaming: Bool = false
    @Published var message = ""
    @Published var isLoginForBroadcast = false
    @Published var isPopupPresented = false
    @Published var responsesFromServer = ""
    //Popup alert/message/diagrame
    enum PopupState {
        case gRPCError(String)
        case noConnection, notLogin
    }
    @Published var popupState: PopupState?
    
    //gRPC streaming call
    private let asyncClient = GRPCClientStub.shared.asyncClient
    private var bidiStreamCall: GRPCAsyncBidirectionalStreamingCall<Storage_BidiStreamRequest, Storage_BidiStreamResponse>? = nil
    init(){
        print("BidiStreamService init()")
    }
    
    func establishConnection(closure: @escaping () async throws -> Void){
        print("BidiStreamService - establishConnection()")
        
        var callOptions = CallOptions()
        callOptions.customMetadata.add(name: "storage.app", value: self.uuid) //[metaKey:uuid] as the header
        
        bidiStreamCall = asyncClient.makeBidiStreamCall(callOptions: callOptions)
        self.isInBidiStreaming = true
        
        Task{
            do{
                try await withThrowingTaskGroup(of: Void.self) { group in
                    // group1
                    group.addTask {
                        for try await res in await self.bidiStreamCall!.responseStream {
                            print("Received: \(res.broadcastMessage)")
                            DispatchQueue.main.async {
                                self.responsesFromServer = res.broadcastMessage
                                if res.broadcastMessage.contains("login") { //temporary setup, it can be more specific
                                    self.isLoginForBroadcast = true
                                }
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
                        print("Error being ignored (.unavailable)")
                    } else {
                        self.popupState = .gRPCError("\(err)")
                        self.isPopupPresented = true
                    }
                }
            }
        }
    }
    
    func login() {
        print("BidiStreamService - login()")
        if self.bidiStreamCall == nil {
            self.popupState = .noConnection
            self.isPopupPresented = true
        } else {
            let req: Storage_BidiStreamRequest = .with{
                $0.userUuid = uuid
                $0.login = "login"
            }
            
            Task{
                do{
                    try await bidiStreamCall?.requestStream.send(req)
                    self.isLoginForBroadcast = true
                } catch {
                    print(error)
                    self.popupState = .gRPCError("\(error)")
                    self.isPopupPresented = true
                }
            }
        }
    }
    
    func logout(){
        print("BidiStreamService - logout()")
        
        let req: Storage_BidiStreamRequest = .with{
            $0.userUuid = uuid
            $0.logout = "logout"
        }
        
        Task{
            do{
                try await withThrowingTaskGroup(of: Void.self) { group in
                    // group1
                    group.addTask {
                        try await self.bidiStreamCall?.requestStream.send(req)
                    }
                    // group2
                    group.addTask {
                        try await self.endCall()
                    }
                    try await group.waitForAll()
                }
            } catch {
                print(error)
                self.popupState = .gRPCError("\(error)")
                self.isPopupPresented = true
            }
        }
    }
    
    func broadcast(){
        print("BidiStreamService - broadcast()")
        if !self.isLoginForBroadcast {
            self.popupState = .notLogin
            self.isPopupPresented = true
        } else {
            let req: Storage_BidiStreamRequest = .with{
                $0.userUuid = uuid
                $0.broadcast = message
            }
            
            Task{
                do{
                    try await bidiStreamCall?.requestStream.send(req)
                } catch {
                    print(error)
                    self.popupState = .gRPCError("\(error)")
                    self.isPopupPresented = true
                }
            }
        }
    }
    
    func endCall() throws {
        Task{
            try? await bidiStreamCall?.requestStream.finish()
            self.isInBidiStreaming = false
            self.isLoginForBroadcast = false
            self.responsesFromServer = ""
            self.bidiStreamCall = nil
        }
    }
}
