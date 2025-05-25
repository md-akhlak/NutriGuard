import SwiftUI
import PhotosUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    let userName: String
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showImagePicker = false
    @State private var showActionSheet = false
    @State private var selectedImage: UIImage?
    @State private var showMenuAnalysis = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Welcome Section
            VStack(spacing: 15) {
                Text("Welcome, \(userName)!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Need help choosing the perfect meal?")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 50)
            
            // Recommendation Card
            VStack(spacing: 20) {
                Image(systemName: "fork.knife.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.red)
                
                Text("Let us help you find the perfect meal that matches your health profile!")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Take a photo of the menu or select from your gallery")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
            .cornerRadius(20)
            .shadow(radius: 5)
            .padding(.horizontal)
            
            Spacer()
            
            // Camera Button
            Button(action: {
                showActionSheet = true
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                    Text("Scan Menu")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(15)
                .shadow(radius: 5)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showCamera) {
            // Camera view will be implemented here
            Text("Camera View")
        }
        .sheet(isPresented: $showPhotoLibrary) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showMenuAnalysis) {
            if let image = selectedImage {
                MenuAnalysisView(menuImage: image)
            }
        }
        .confirmationDialog("Choose Image Source", isPresented: $showActionSheet) {
            Button("Take Photo") {
                showCamera = true
            }
            Button("Choose from Library") {
                showPhotoLibrary = true
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


#Preview {
    HomeView(userName: "John Doe")
} 
