import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var rotation = 0.0
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.3), Color.blue.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.linearGradient(
                            colors: [.green, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .rotationEffect(.degrees(rotation))
                        .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text("NutriGuard")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.linearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    
                    Text("Eat Smart. Live Safe.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.top, -10)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 0.9
                        self.opacity = 1.0
                    }
                    
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        self.rotation = 360
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            self.isActive = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreen()
} 