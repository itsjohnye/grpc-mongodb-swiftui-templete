//
//  BidiStreamView.swift
//  Storage
//
//  Created by John Ye on 2022/7/29.
//

import SwiftUI

//Bidiretional-Streaming RPCs
struct BidiStreamView: View {
    
    @EnvironmentObject var service: BidiStreamService
    
    var body: some View {
        VStack {
            Text("gRPC Bidirectional Streaming")
            Form {
                Text("uuid: \(service.uuid)").font(.caption)
                Text("isInBidiStreaming? ") + Text(service.isInBidiStreaming ? "True" : "False").foregroundColor(service.isInBidiStreaming ? .green : .red)
                Text("isLoginForBroadcast? ") + Text(service.isLoginForBroadcast ? "True" : "False").foregroundColor(service.isLoginForBroadcast ? .green : .red)
                Section(header: Text("action")){

                    Button("Login", action: {
                        service.establishConnection {
                            service.login()
                        }
                    }).frame(maxWidth: .infinity, alignment: .center)
                    Button("Logout & End call", action: {
                        service.logout()
                    }).frame(maxWidth: .infinity, alignment: .center)
                }
                
                Section(header: Text("message").bold()){
                    TextField("enter a message for broadcast", text: $service.message)
                    
                    Button("Greet", action: {
                        service.broadcast()
                    }).frame(maxWidth: .infinity, alignment: .center)
                }
                Section(header: Text("Bidi-stream responses")){
                    Text(service.responsesFromServer)
                        .minimumScaleFactor(0.5)
                        .frame(minHeight:100)
                }
            }
        }
        .alert(isPresented: $service.isPopupPresented){
            switch service.popupState {
            case .gRPCError(let error):
                return Alert(title: Text("Error"), message: Text(error), dismissButton: .cancel())
            case .noConnection:
                return Alert(title: Text("Error"), message: Text("Establish connection first in order to start BidiStreaming"), dismissButton: .cancel())
            case .notLogin:
                return Alert(title: Text("Error"), message: Text("Please login before broadcast"), dismissButton: .cancel())
            case .none:
                return Alert(title: Text(""))
                
            }
        }
    }
}

struct BidiStreamView_Previews: PreviewProvider {
    static var previews: some View {
        BidiStreamView().environmentObject(BidiStreamService())
    }
}
