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
final class UnaryViewModel: ObservableObject {
    @AppStorage("useruuid") var uuid: String = ""
    @Published var name = ""
    @Published var habit = ""
    @Published var isPopupPresented = false
    
    //Popup alert/message/diagrame
    enum PopupState {
        case gRPCError(String)
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
        print("getProfileWithAsync()")
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
                self.popupState = .gRPCError("\(error)")
                self.isPopupPresented = true
            }
        }
    }
    
    func updateProfileWithAsync()  {
        print("updateProfileWithAsync()")
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
                self.popupState = .gRPCError("\(error)")
                self.isPopupPresented = true
            }
        }
    }
    
}

//MARK: Nio with Combine method
extension UnaryViewModel {
    private var getProfileWithNioPublisher: AnyPublisher<Storage_GetProfileResponse, GRPCStatus> {  //returns GRPCStatus which confirms to the Error protocol
        Deferred{       //Using Deferred wraps Future: Wait for the subscription before executing the closure to create the Publisher for the new Subscriber.
            Future<Storage_GetProfileResponse, GRPCStatus> { promise in //Here, a Publisher of type Future (asynchronous, one-time) is created.
                let req: Storage_GetProfileRequest = .with{
                    $0.userUuid = self.uuid
                }
                let call = self.nioClient.getProfile(req, callOptions: self.callOptions)
                call.response.whenSuccess{
                    promise(.success($0))   //$0 is 'syntactic sugar', indicating the first parameter, and the corresponding parameter type will be judged according to the function type. Here refers to the first parameter of the response.whenSuccess closure, which is the value of type Storage_GetProfileResponse.
                }
                
                //The status EventLoofFuture succeeds when RPC fails.
                call.status.whenSuccess{
                    promise(.failure($0))   //$0 refers to the first parameter of the status.whenSuccess closure, which is a value of type GRPCStatus.
                }
            }
        }
        .subscribe(on: DispatchQueue.global())  //subscribe(on:) specifies the scheduler for subscription, cancellation, and request. The above operations are performed in the child thread and do not block the main thread.
        .receive(on: DispatchQueue.main)    //receive(on:) specifies the scheduler on which to receive elements from the publisher. From here, the Publisher dispatches the main thread, such as updating the UI.
        .eraseToAnyPublisher()  //AnyPublisher<Scorer_UUID,Error>
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
        print("getProfileWithNio()")
        getProfileWithNioPublisher
            .sink(receiveCompletion: {completion in
                switch completion {
                case .failure(let status):
                    self.popupState = .gRPCError(status.description)
                    self.isPopupPresented = true
                case .finished:
                    break
                }
            }, receiveValue: { rec in
                self.name = rec.name
                self.habit = rec.habit
                
            })
            .store(in: &cancellables)
    }
    
    func updateProfileWithNio()  {
        print("updateProfileWithNio()")
        updateProfileWithNioPublisher
            .sink(receiveCompletion: {completion in
                switch completion {
                case .failure(let status):
                    self.popupState = .gRPCError(status.description)
                    self.isPopupPresented = true
                case .finished:
                    break
                }
            }, receiveValue: { rec in
                self.name = rec.name
                self.habit = rec.habit
                
            })
            .store(in: &cancellables)
    }
}
