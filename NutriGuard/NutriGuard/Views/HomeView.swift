import SwiftUI
import VisionKit
import PhotosUI

struct HomeView: View {
    @ObservedObject var userProfile: UserProfile
    @StateObject private var menuScannerViewModel: MenuScannerViewModel
    @State private var showingProfileSheet = false
    @State private var selectedItem: PhotosPickerItem?
    @Environment(\.colorScheme) var colorScheme
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
        _menuScannerViewModel = StateObject(wrappedValue: MenuScannerViewModel(userProfile: userProfile))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Card
                profileCard
                
                // Scanner Section
                scannerSection
                
                // Recent Scans
                if !menuScannerViewModel.analyzedItems.isEmpty {
                    recentScansSection
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("NutriGuard")
        .sheet(isPresented: $showingProfileSheet) {
            NavigationView {
                ProfileView(userProfile: userProfile)
                    .navigationBarItems(trailing: Button("Done") {
                        showingProfileSheet = false
                    })
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await menuScannerViewModel.processImage(image)
                }
            }
        }
    }
    
    private var profileCard: some View {
        Button(action: { showingProfileSheet = true }) {
            HStack(spacing: 16) {
                // Profile Image
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(userProfile.name.isEmpty ? "Set up your profile" : "Hello, \(userProfile.name)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    if !userProfile.medicalConditions.isEmpty {
                        Text("\(userProfile.medicalConditions.count) medical conditions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    private var scannerSection: some View {
        VStack(spacing: 16) {
            Text("Scan Menu")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                // Camera Button
                Button(action: {
                    // Handle camera action
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 30))
                        Text("Take Photo")
                            .font(.callout)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Gallery Button
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 30))
                        Text("Gallery")
                            .font(.callout)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var recentScansSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Scans")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink(destination: MenuAnalysisView(viewModel: menuScannerViewModel, userProfile: userProfile)) {
                    Text("See All")
                        .foregroundColor(.blue)
                }
            }
            
            ForEach(menuScannerViewModel.analyzedItems.prefix(3), id: \.name) { item in
                MenuItemAnalysisCard(item: item)
            }
        }
    }
} 