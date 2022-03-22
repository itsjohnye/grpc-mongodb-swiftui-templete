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
        NavigationView {
            Form {
                Text("uuid: \(vm.uuid)")
                Section(header: Text("Name").bold()){
                    TextField("", text: $vm.name)
                }
                Section(header: Text("Habit").bold()){
                    TextField("", text: $vm.habit)
                }
                
                HStack {
                    Spacer()
                    Button("Get Profile", action: {
                        vm.getProfile()
                    })
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    Button("Update Profile", action: {
                        vm.updateProfile()
                    })
                    Spacer()
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
             .navigationTitle("Docker-compose single server")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
