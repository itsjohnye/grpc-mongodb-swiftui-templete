//
//  GRPCService.swift
//  Storage
//
//  Created by John Ye on 2022/3/22.
//

import SwiftUI

@main
struct StorageApp: App {

    @StateObject private var serverStreamService = ServerStreamService()
    @StateObject private var bidiStreamService = BidiStreamService()
    
    @Environment(\.scenePhase)var scenePhase
    @AppStorage("isInServerStreaming") var isInServerStreaming: Bool = false    //store a state if the app switched between background and foreground, so that it reconnects the server in silence
    @AppStorage("isInBidiStreaming") var isInBidiStreaming: Bool = false
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(serverStreamService)
                .environmentObject(bidiStreamService)
        }
        .onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .active:
                print("App is active")
                //reconnection
                if isInServerStreaming {
                    serverStreamService.subscribe {}
                }
                if isInBidiStreaming{
                    bidiStreamService.establishConnection {
                        bidiStreamService.login()
                    }
                }
            case .inactive:
                print("App is inactive")
            case .background:
                print("App is in background")
            @unknown default:
                print("unknown scenePhase value")
            }
        }
    }
}
