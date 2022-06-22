//
//  ContentView.swift
//  Storage
//
//  Created by John Ye on 2022/3/22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var vm = ViewModel()
    var body: some View {
        Form {
            Section(header: Text("Docker-compose single server").bold()){
                Text("uuid: \(vm.uuid)")
            }
            
            Section(header: Text("Name").bold()){
                TextField("", text: $vm.name)
            }
            
            Section(header: Text("Habit").bold()){
                TextField("", text: $vm.habit)
            }
            
            Button("Get Profile", action: {
                vm.getProfile()
            }).frame(maxWidth: .infinity, alignment: .center)
            
            Button("Update Profile", action: {
                vm.updateProfile()
            }).frame(maxWidth: .infinity, alignment: .center)
        }
        .alert(isPresented: $vm.isAlertPresented){
            switch vm.popupState {
            case .gRPCError(let status):
                return Alert(title: Text("gRPC Error"), message: Text("\(status.description)"), dismissButton: .cancel())
            case .none:
                return Alert(title: Text(""))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
