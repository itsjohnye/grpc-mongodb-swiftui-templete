import SwiftUI
import GRPC
import NIO
import Combine

struct ContentView: View {
    
    @State private var message = ""
    @State private var name = ""
    @ObservedObject var viewModel = ViewModel()
    
    var body: some View {
        var anyCancellable = Set<AnyCancellable>()
        NavigationView {
            Form {
                Section(header: Text("Input").bold()){
                    TextField("Enter your name here", text: $name)
                }
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.greeting(name: name)
                            .replaceError(with: .init())
                            .sink(receiveValue: { response in
                                message = "\(response.message)"
                            })
                            .store(in: &anyCancellable)
                    }){
                        Text("get response")
                    }
                    Spacer()
                }
                Section(header: Text("response message").bold()){
                    Text("\(message)")
                }
            }
        }
    }
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
