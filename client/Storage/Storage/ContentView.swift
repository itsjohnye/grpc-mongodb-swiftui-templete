//
//  ContentView.swift
//  Storage
//
//  Created by John Ye on 2022/6/23.
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
        .alert(isPresented: $vm.isAlertPresented){
            switch vm.popupState {
            case .gotError(let error):
                return Alert(title: Text("Error"), message: Text(error.localizedDescription), dismissButton: .cancel())
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
