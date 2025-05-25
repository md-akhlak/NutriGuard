import SwiftUI
import PhotosUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showImagePicker = false
    @State private var showActionSheet = false
    @State private var selectedImage: UIImage?
    @State private var showMenuAnalysis = false
    @State private var showProfileSheet = false
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Profile Button
                HStack {
                    Button(action: {
                        showProfileSheet = true
                    }) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.red)
                            
                            VStack(alignment: .leading) {
                                Text(authViewModel.userName)
                                    .font(.headline)
                                Text("View Profile")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
                        .cornerRadius(15)
                        .shadow(radius: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Welcome Section
                VStack(spacing: 15) {
                    Text("Welcome, \(authViewModel.userName)!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Need help choosing the perfect meal?")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
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
            .sheet(isPresented: $showProfileSheet) {
                ProfileView(showEditProfile: $showEditProfile)
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
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
}

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @Binding var showEditProfile: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 15) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.red)
                        
                        Text(authViewModel.userName)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 30)
                    
                    // Health Profile Sections
                    Group {
                        ProfileSection(title: "Basic Information", items: [
                            ("Age", "\(authViewModel.healthProfile.age)"),
                            ("Gender", authViewModel.healthProfile.gender),
                            ("Activity Level", authViewModel.healthProfile.activityLevel)
                        ])
                        
                        ProfileSection(title: "Medical Information", items: [
                            ("Chronic Conditions", authViewModel.healthProfile.chronicConditions.joined(separator: ", ")),
                            ("Food Allergies", authViewModel.healthProfile.foodAllergies.joined(separator: ", ")),
                            ("Medications", authViewModel.healthProfile.medications.joined(separator: ", "))
                        ])
                        
                        ProfileSection(title: "Dietary Preferences", items: [
                            ("Diet Type", authViewModel.healthProfile.dietType),
                            ("Permanent Dislikes", authViewModel.healthProfile.permanentDislikes.joined(separator: ", ")),
                            ("Long Term Goals", authViewModel.healthProfile.longTermGoals.joined(separator: ", "))
                        ])
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitle("Profile", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Edit") {
                    showEditProfile = true
                }
            )
        }
    }
}

struct ProfileSection: View {
    let title: String
    let items: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(items, id: \.0) { item in
                    HStack(alignment: .top) {
                        Text(item.0)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 120, alignment: .leading)
                        
                        Text(item.1.isEmpty ? "Not specified" : item.1)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct EditProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showPatientForm = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Edit Profile")) {
                    Button(action: {
                        showPatientForm = true
                    }) {
                        HStack {
                            Text("Update Health Information")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationBarTitle("Edit Profile", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showPatientForm) {
                PatientFormView()
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
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

//#Preview {
//    HomeView(userName: "John Doe")
//} 
