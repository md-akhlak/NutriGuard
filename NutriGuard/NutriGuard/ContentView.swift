import SwiftUI

struct ContentView: View {
    @State private var showForm = false
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    @State private var showHome = false
    
    var body: some View {
        if !userName.isEmpty {
            HomeView(userName: userName)
        } else if showForm {
            NavigationStack {
                PatientFormView(initialName: userName) { savedName in
                    self.userName = savedName
                    UserDefaults.standard.set(savedName, forKey: "userName")
                }
                .navigationTitle("Setup Profile")
                .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            // Splash Screen
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                Image("SplasScreen")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
            .onAppear {
                // Automatically navigate to form after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showForm = true
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
} 
