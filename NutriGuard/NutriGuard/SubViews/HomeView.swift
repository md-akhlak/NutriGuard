import SwiftUI
import PhotosUI
import AVFoundation

struct HomeView: View {
    @State var userName: String
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showProfileEdit = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var showImageSourceOptions = false
    @State private var showMenuAnalysis = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Profile Card Section
                Button(action: {
                    showProfileEdit = true
                }) {
                    HStack(spacing: 15) {
                        // Profile Circle
                        Circle()
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(userName.prefix(1).uppercased())
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.red.gradient)
                            )
                        
                        // User Info
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome,")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(userName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        // Chevron
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                }
                
                // Need help text
                Text("Need help choosing the perfect meal?")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 5)
                
                // Menu Analysis Card
                VStack(spacing: 25) {
                    // Icon
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundStyle(.red.gradient)
                        )
                    
                    // Text Content
                    VStack(spacing: 15) {
                        Text("Let us help you find the perfect meal that matches your health profile!")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text("Take a photo of the menu or select from your gallery")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.background)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                Spacer()
                
                // Scan Menu Button
                Button(action: {
                    showImageSourceOptions = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title3)
                        Text("Scan Menu")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.gradient)
                    .clipShape(Capsule())
                    .shadow(color: .red.opacity(0.3), radius: 5, y: 3)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showProfileEdit) {
                NavigationStack {
                    PatientFormView(initialName: userName) { updatedName in
                        self.userName = updatedName
                        showProfileEdit = false
                    }
                    .navigationTitle("Edit Profile")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showProfileEdit = false
                            }
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showMenuAnalysis) {
                if let image = selectedImage {
                    MenuAnalysisView(menuImage: image)
                }
            }
            .confirmationDialog("Choose Image Source", isPresented: $showImageSourceOptions) {
                Button("Take Photo") {
                    sourceType = .camera
                    showImagePicker = true
                }
                Button("Choose from Library") {
                    sourceType = .photoLibrary
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .onChange(of: selectedImage) { newImage in
                if newImage != nil {
                    showMenuAnalysis = true
                }
            }
        }
    }
}

#Preview {
    HomeView(userName: "John Doe")
} 
