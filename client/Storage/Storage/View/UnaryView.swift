//
//  ContentView.swift
//  Storage
//
//  Created by John Ye on 2022/6/23.
//

import SwiftUI

//Unary RPC
struct UnaryView: View {
    @ObservedObject var vm = UnaryViewModel()
    var body: some View {
        VStack {
            Text("gRPC Unary call")
            Form {
                Text("uuid: \(vm.uuid)").font(.caption)
                Section(header: Text("Name").bold()){
                    TextField("", text: $vm.name)
                }
                
                Section(header: Text("Habit").bold()){
                    TextField("", text: $vm.habit)
                }
                
                Section(header: Text("async method")){
                Button("Get profile with async", action: {
                    vm.getProfileWithAsync()
                }).frame(maxWidth: .infinity, alignment: .center)
                
                Button("Update profile with async", action: {
                    vm.updateProfileWithAsync()
                }).frame(maxWidth: .infinity, alignment: .center)
                }
                
                Section(header: Text("nio method")){
                Button("Get profile with nio", action: {
                    vm.getProfileWithNio()
                }).frame(maxWidth: .infinity, alignment: .center)
                
                Button("Update profile with nio", action: {
                    vm.updateProfileWithNio()
                }).frame(maxWidth: .infinity, alignment: .center)
                }
                
            }
            .alert(isPresented: $vm.isPopupPresented){
                switch vm.popupState {
                case .gRPCError(let error):
                    return Alert(title: Text("Error"), message: Text(error), dismissButton: .cancel())
                case .none:
                    return Alert(title: Text(""))
                }
            }
        }
    }
}

struct UnaryView_Previews: PreviewProvider {
    static var previews: some View {
        UnaryView()
    }
}
