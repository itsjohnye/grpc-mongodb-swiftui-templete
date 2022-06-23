//
//  ViewModel.swift
//  Storage
//
//  Created by John Ye on 2022/6/23.
//

import SwiftUI
import GRPC
import NIO
import Combine
import NIOHPACK

@MainActor      //A singleton actor whose executor is equivalent to the main dispatch queue
final class ViewModel: ObservableObject {
    let uuid = "001"    //const
    @Published var name = ""
    @Published var habit = ""
    @Published var isAlertPresented = false
    
    //Popup alert/message/diagrame
    enum PopupState {
        case gotError(Error)
    }
    @Published var popupState: PopupState?
    
    //Combine
    private var cancellables = Set<AnyCancellable>()
    
    //gRPC call
    let callOptions = CallOptions(timeLimit: .timeout(.seconds(3)))
    let asyncClient = GRPCClientStub.shared.asyncClient
    let nioClient = GRPCClientStub.shared.nioClient
    
    //MARK: Async method
    func getProfileWithAsync() {
        print("getProfileWithAsync function invoked")
        let req: Storage_GetProfileRequest = .with{
            $0.userUuid = self.uuid
        }
        Task{
            do{
                let response = try await self.asyncClient.getProfile(req,callOptions: self.callOptions)
                self.name = response.name
                self.habit = response.habit
            } catch {
                print(error)
                self.popupState = .gotError(error)
                self.isAlertPresented = true
            }
        }
    }
    
    func updateProfileWithAsync()  {
        print("updateProfileWithAsync function invoked")
        let req: Storage_UpdateProfileRequest = .with{
            $0.userUuid = self.uuid
            $0.name = self.name
            $0.habit = self.habit
        }
        Task{
            do{
                let response = try await self.asyncClient.updateProfile(req, callOptions: self.callOptions)
                self.name = response.name
                self.habit = response.habit
            } catch {
                print(error)
                self.popupState = .gotError(error)
                self.isAlertPresented = true
            }
        }
    }
  
}

//MARK: Nio with Combine method
extension ViewModel {
    private var getProfileWithNioPublisher: AnyPublisher<Storage_GetProfileResponse, GRPCStatus> {
            Deferred{
                Future<Storage_GetProfileResponse, GRPCStatus> { promise in
                    let req: Storage_GetProfileRequest = .with{
                        $0.userUuid = self.uuid
                    }
                    let call = self.nioClient.getProfile(req, callOptions: self.callOptions)
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
        
        private var updateProfileWithNioPublisher: AnyPublisher<Storage_UpdateProfileResponse, GRPCStatus> {
            Deferred{
                Future<Storage_UpdateProfileResponse, GRPCStatus> { promise in
                    let req: Storage_UpdateProfileRequest = .with {
                        $0.userUuid = self.uuid
                        $0.name = self.name
                        $0.habit = self.habit
                    }
                    let call = self.nioClient.updateProfile(req, callOptions: self.callOptions)
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
    
    func getProfileWithNio() {
        print("getProfileWithNio function invoked")
                getProfileWithNioPublisher
                    .sink(receiveCompletion: {completion in
                        switch completion {
                        case .failure(let status):
                            self.popupState = .gotError(status)
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
    
    func updateProfileWithNio()  {
        print("updateProfileWithNio function invoked")
        updateProfileWithNioPublisher
            .sink(receiveCompletion: {completion in
                switch completion {
                case .failure(let status):
                    self.popupState = .gotError(status)
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
