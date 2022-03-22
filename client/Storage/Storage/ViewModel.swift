//
//  ViewModel.swift
//  Storage
//
//  Created by John Ye on 2022/3/22.
//

import SwiftUI
import GRPC
import NIO
import Combine
import NIOHPACK

final class ViewModel: ObservableObject {
    let uuid = "001"    //const
    @Published var name = ""
    @Published var habit = ""
    @Published var isAlertPresented = false
    
    //Popup alert/message/diagrame
    enum PopupState {
        case gRPCError(gRPCStatus: GRPCStatus)  //gRPC Error handler
    }
    @Published var popupState: PopupState?
    
    //Combine
    private var cancellables = Set<AnyCancellable>()
    //gRPC call
    let client = GRPCClientStub.shared.client
    let callOptions = CallOptions(timeLimit: .timeout(.seconds(3)))    
    
    private var getProfilePublisher: AnyPublisher<Storage_GetProfileResponse, GRPCStatus> {
        Deferred{
            Future<Storage_GetProfileResponse, GRPCStatus> { promise in
                let req: Storage_GetProfileRequest = .with{
                    $0.userUuid = self.uuid
                }
                let call = self.client.getProfile(req, callOptions: self.callOptions)
                
                call.response.whenSuccess{
                    promise(.success($0))
                }
              
                call.status.whenSuccess{
                    promise(.failure($0))
                }
            }
        }
        .subscribe(on: DispatchQueue.global())
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    private var updateProfilePublisher: AnyPublisher<Storage_UpdateProfileResponse, GRPCStatus> {
        Deferred{
            Future<Storage_UpdateProfileResponse, GRPCStatus> { promise in
                let req: Storage_UpdateProfileRequest = .with {
                    $0.userUuid = self.uuid
                    $0.name = self.name
                    $0.habit = self.habit
                }
                let call = self.client.updateProfile(req, callOptions: self.callOptions)
                
                call.response.whenSuccess{
                    promise(.success($0))
                }
              
                call.status.whenSuccess{
                    promise(.failure($0))
                }
            }
        }
        .subscribe(on: DispatchQueue.global())
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    func getProfile() {
        print("getProfile function invoked")
        getProfilePublisher
            .sink(receiveCompletion: {completion in
                switch completion {
                case .failure(let error):
                    self.popupState = .gRPCError(gRPCStatus: error)
                    self.isAlertPresented = true
                case .finished:
                    break
                }
            }, receiveValue: { rec in
                print("getProfile recived.")
                self.name = rec.name
                self.habit = rec.habit
                
            })
            .store(in: &cancellables)
    }
    
    func updateProfile() {
        print("updateProfile function invoked")
        updateProfilePublisher
            .sink(receiveCompletion: {completion in
                switch completion {
                case .failure(let error):
                    self.popupState = .gRPCError(gRPCStatus: error)
                    self.isAlertPresented = true
                case .finished:
                    break
                }
            }, receiveValue: { rec in
                print("updateProfile recived.")
                self.name = rec.name
                self.habit = rec.habit
                
            })
            .store(in: &cancellables)
    }
    
    
    
    
    
    
}
