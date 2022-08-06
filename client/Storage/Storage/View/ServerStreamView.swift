//
//  StreamingView.swift
//  Storage
//
//  Created by John Ye on 2022/7/27.
//

import SwiftUI

//Server-Streaming RPCs
struct ServerStreamView: View {
    
    @EnvironmentObject var service: ServerStreamService
    
    var body: some View {
        VStack {
            Text("gRPC Server Streaming")
            Form {
                Text("uuid: \(service.uuid)").font(.caption)
                Text("isInServerStreaming? ") + Text(service.isInServerStreaming ? "True" : "False").foregroundColor(service.isInServerStreaming ? .green : .red)
                Text("isSubscribed? ") + Text(service.isSubscribed ? "True" : "False").foregroundColor(service.isSubscribed ? .green : .red)
                
                Section(header: Text("action")){
                    Button("Subscribe", action: {
                        service.subscribe {}
                    }).frame(maxWidth: .infinity, alignment: .center)
                    
                    Button("Unsubscribe", action: {
                        service.unsubscribe()
                    }).frame(maxWidth: .infinity, alignment: .center)
                    
                }
                Section(header: Text("message").bold()){
                    TextField("enter a message for broadcast", text: $service.message)
                    Button("Greet", action: {
                        service.broadcast()
                    }).frame(maxWidth: .infinity, alignment: .center)
                }
                Section(header: Text("server-stream responses")){
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
            case .none:
                return Alert(title: Text(""))
            }
        }
    }
}

struct ServerStreamView_Previews: PreviewProvider {
    static var previews: some View {
        ServerStreamView().environmentObject(ServerStreamService())
    }
}
