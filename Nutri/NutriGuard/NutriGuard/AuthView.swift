import SwiftUI

struct AuthView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var isSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo or App Name
                Text("NutriGuard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Text("Your Health, Your Choice")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Form
                VStack(spacing: 15) {
                    // Email Field
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    // Password Field
                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(isSignUp ? .newPassword : .password)
                    
                    // Error Message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // Sign In/Up Button
                    Button(action: {
                        if isSignUp {
                            viewModel.signUp()
                        } else {
                            viewModel.signIn()
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isSignUp ? "Sign Up" : "Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(viewModel.isLoading)
                    
                    // Toggle Sign In/Up
                    Button(action: {
                        isSignUp.toggle()
                        viewModel.errorMessage = nil
                    }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 30)
            }
            .padding()
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $viewModel.isNewUser) {
            PatientFormView()
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
} 

