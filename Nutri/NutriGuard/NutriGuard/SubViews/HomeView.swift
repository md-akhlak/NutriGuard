import SwiftUI
import PhotosUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

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
            CameraView(selectedImage: $selectedImage)
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
