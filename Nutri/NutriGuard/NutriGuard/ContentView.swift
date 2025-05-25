import SwiftUI

struct ContentView: View {
    @State private var showForm = false
    
    var body: some View {
        ZStack {
            if !showForm {
                // Splash Screen
                ZStack {
                    Color.white
                        .ignoresSafeArea()
                    
                    Image("image")
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
            } else {
                // Patient Form
                PatientFormView()
            }
        }
    }
}

#Preview {
    ContentView()
} 
