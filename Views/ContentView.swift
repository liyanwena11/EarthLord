import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn: Bool = false
    
    var body: some View {
        if isLoggedIn {
            MainMapView()
                .onAppear {
                    Task {
                        if await AuthManager.shared.getCurrentUser() == nil {
                            isLoggedIn = false
                        }
                    }
                }
        } else {
            AuthView()
                .onAppear {
                    Task {
                        if await AuthManager.shared.getCurrentUser() != nil {
                            isLoggedIn = true
                        }
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
