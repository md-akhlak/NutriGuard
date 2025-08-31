import SwiftUI

struct DishAnalysisView: View {
    @State private var menuItem: MenuItem
    @State private var analysis: HealthAnalysis?
    @State private var isLoading = true
    @State private var error: Error?
    @Environment(\.dismiss) var dismiss
    // Image generation state
    @State private var dishImage: UIImage? = nil
    @State private var isImageLoading: Bool = false
    @State private var imageError: String? = nil
    
    init(menuItem: MenuItem) {
        self._menuItem = State(initialValue: menuItem)
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 28) {
                    // Header Card
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.95))
                            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
                        VStack(spacing: 12) {
                            HStack {
                                Button(action: { dismiss() }) {
                                    Image(systemName: "chevron.left")
                                        .font(.title2)
                                        .foregroundColor(.red)
                                        .padding(8)
                                        .background(Color.red.opacity(0.08))
                                        .clipShape(Circle())
                                }
                                Spacer()
                            }
                            .padding(.top, 8)
                            .padding(.leading, 8)
                            // Dish Image
                            Group {
                                if isImageLoading {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                        .padding(.top, 8)
                                } else if let dishImage = dishImage {
                                    Image(uiImage: dishImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 120, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                        .shadow(radius: 6)
                                        .padding(.top, 8)
                                } else if let imageError = imageError {
                                    VStack(spacing: 4) {
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 80, height: 80)
                                            .foregroundColor(.gray.opacity(0.3))
                                        Text(imageError)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.top, 8)
                                } else {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(.gray.opacity(0.3))
                                        .padding(.top, 8)
                                }
                            }
                            
                            Text(menuItem.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                                .animation(.easeInOut(duration: 0.5), value: menuItem.name)
                            HStack(spacing: 8) {
                                Image(systemName: "fork.knife")
                                    .foregroundStyle(.red.gradient)
                                Text(menuItem.cuisine)
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    if isLoading {
                        VStack(spacing: 18) {
                            ProgressView()
                                .scaleEffect(1.7)
                                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                            Text("Analyzing dish...")
                                .foregroundColor(.secondary)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal)
                    } else if let error = error {
                        VStack(spacing: 18) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.red)
                            Text("Error analyzing dish: \(error.localizedDescription)")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button(action: { retryAnalysis() }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Retry")
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.red.gradient)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal)
                    } else if let analysis = analysis {
                        // Health Status Card
                        VStack(spacing: 18) {
                            HStack(spacing: 10) {
                                Image(systemName: analysis.isHealthy ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(analysis.isHealthy ? Color.green.gradient : Color.red.gradient)
                                Text(analysis.isHealthy ? "Healthy Choice" : "Consider Alternatives")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(analysis.isHealthy ? .green : .red)
                            }
                            Text(analysis.reason)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(analysis.isHealthy ? Color.green.opacity(0.08) : Color.red.opacity(0.08))
                                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
                        )
                        .padding(.horizontal)
                        .transition(.opacity)
                        
                        // Health Impacts
                        if !analysis.healthImpacts.isEmpty {
                            SectionCard(title: "Health Impacts", icon: "heart.fill", iconColor: .red) {
                                ForEach(analysis.healthImpacts, id: \.self) { impact in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundStyle(.orange.gradient)
                                        Text(impact)
                                            .font(.body)
                                    }
                                }
                            }
                        }
                        // Recommendations
                        if !analysis.recommendations.isEmpty {
                            SectionCard(title: "Recommendations", icon: "lightbulb.fill", iconColor: .yellow) {
                                ForEach(analysis.recommendations, id: \.self) { recommendation in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundStyle(.blue.gradient)
                                        Text(recommendation)
                                            .font(.body)
                                    }
                                }
                            }
                        }
                        // Allergens
                        if !menuItem.allergens.isEmpty {
                            SectionCard(title: "Allergens", icon: "exclamationmark.triangle.fill", iconColor: .red) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(menuItem.allergens, id: \.self) { allergen in
                                            HStack {
                                                Image(systemName: "allergens")
                                                    .foregroundColor(.red)
                                                Text(allergen)
                                            }
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.red.opacity(0.1))
                                            .foregroundColor(.red)
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                        // Nutritional Information
                        SectionCard(title: "Nutritional Information", icon: "chart.bar.fill", iconColor: .purple) {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 15) {
                                ForEach(Array(menuItem.nutritionalInfo.keys.sorted()), id: \.self) { key in
                                    VStack {
                                        HStack {
                                            Image(systemName: nutritionIcon(for: key))
                                                .foregroundStyle(nutritionColor(for: key).gradient)
                                            Text(key)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        Text(menuItem.nutritionalInfo[key] ?? "")
                                            .font(.headline)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.purple.opacity(0.08))
                                    )
                                }
                            }
                        }
                        // Alternative Options
                        if !menuItem.alternativeOptions.isEmpty {
                            SectionCard(title: "Alternative Options", icon: "arrow.triangle.swap", iconColor: .green) {
                                ForEach(menuItem.alternativeOptions, id: \.self) { option in
                                    HStack {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundStyle(.blue.gradient)
                                        Text(option)
                                            .font(.body)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .padding(.top, 8)
            .animation(.easeInOut(duration: 0.5), value: isLoading)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            analyzeDish()
            generateDishImage()
        }
    }
    
    private func nutritionIcon(for key: String) -> String {
        switch key.lowercased() {
        case "calories": return "flame.fill"
        case "protein": return "figure.strengthtraining"
        case "carbs": return "leaf.fill"
        case "fat": return "drop.fill"
        case "fiber": return "chart.line.uptrend.xyaxis"
        case "sugar": return "cube.fill"
        case "sodium": return "salt.fill"
        default: return "circle.fill"
        }
    }
    
    private func nutritionColor(for key: String) -> Color {
        switch key.lowercased() {
        case "calories": return .red
        case "protein": return .blue
        case "carbs": return .green
        case "fat": return .orange
        case "fiber": return .purple
        case "sugar": return .pink
        case "sodium": return .yellow
        default: return .gray
        }
    }
    
    private func analyzeDish() {
        error = nil
        isLoading = true
        print("📊 Starting dish analysis for: \(menuItem.name)")
        guard let userProfile = MenuImageProcessor.shared.userProfile else {
            print("❌ Error: User profile not found")
            error = NSError(domain: "DishAnalysisView", code: -1, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
            isLoading = false
            return
        }
        
        print("👤 User profile found with conditions: \(userProfile.chronicConditions)")
        
        Task {
            do {
                print("🤖 Calling Gemini API for analysis...")
                let (analysis, nutritionalInfo) = try await GeminiService.shared.analyzeMenuItem(menuItem, userProfile: userProfile)
                print("✅ Gemini API analysis completed successfully")
                print("📝 Analysis result - Healthy: \(analysis.isHealthy)")
                print("📝 Analysis reason: \(analysis.reason)")
                print("📝 Health impacts: \(analysis.healthImpacts)")
                print("📝 Recommendations: \(analysis.recommendations)")
                print("📝 Nutritional info: \(nutritionalInfo)")
                
                await MainActor.run {
                    self.analysis = analysis
                    self.menuItem.nutritionalInfo = nutritionalInfo
                    self.isLoading = false
                }
            } catch {
                print("❌ Error during Gemini API analysis: \(error.localizedDescription)")
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    private func retryAnalysis() {
        analyzeDish()
    }
    
    // MARK: - Dish Image Generation
    private func generateDishImage() {
        isImageLoading = true
        imageError = nil
        dishImage = nil
        Task {
            do {
                let data = try await GeminiService.shared.generateDishImage(
                    name: menuItem.name,
                    description: menuItem.description,
                    cuisine: menuItem.cuisine
                )
                if let data, let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.dishImage = uiImage
                        self.isImageLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.imageError = "No image generated."
                        self.isImageLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.imageError = "Failed to load image."
                    self.isImageLoading = false
                }
            }
        }
    }
}

// MARK: - SectionCard Helper
private struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor.gradient)
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            content()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal)
    }
} 