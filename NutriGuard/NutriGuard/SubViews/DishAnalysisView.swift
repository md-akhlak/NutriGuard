import SwiftUI

struct DishAnalysisView: View {
    @State var menuItem: MenuItem
    @State private var analysis: HealthAnalysis?
    @State private var isLoading = true
    @State private var error: Error?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 12) {
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
                .padding(.top)
                
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Analyzing dish...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else if let error = error {
                    VStack(spacing: 15) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("Error analyzing dish: \(error.localizedDescription)")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
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
                    )
                    .transition(.opacity)
                    
                    // Health Impacts
                    if !analysis.healthImpacts.isEmpty {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.red.gradient)
                                Text("Health Impacts")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            
                            ForEach(analysis.healthImpacts, id: \.self) { impact in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(.orange.gradient)
                                    Text(impact)
                                        .font(.body)
                                }
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.orange.opacity(0.08))
                        )
                    }
                    
                    // Recommendations
                    if !analysis.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(.yellow.gradient)
                                Text("Recommendations")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            
                            ForEach(analysis.recommendations, id: \.self) { recommendation in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundStyle(.blue.gradient)
                                    Text(recommendation)
                                        .font(.body)
                                }
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.yellow.opacity(0.08))
                        )
                    }
                    
                    // Allergens
                    if !menuItem.allergens.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red.gradient)
                                Text("Allergens")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            
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
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.red.opacity(0.08))
                        )
                    }
                    
                    // Nutritional Information
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.bar.fill")
                                .foregroundStyle(.purple.gradient)
                            Text("Nutritional Information")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        
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
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.purple.opacity(0.08))
                    )
                    
                    // Alternative Options
                    if !menuItem.alternativeOptions.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.swap")
                                    .foregroundStyle(.green.gradient)
                                Text("Alternative Options")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            
                            ForEach(menuItem.alternativeOptions, id: \.self) { option in
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundStyle(.blue.gradient)
                                    Text(option)
                                        .font(.body)
                                }
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.green.opacity(0.08))
                        )
                    }
                }
            }
            .padding()
            .animation(.easeInOut(duration: 0.5), value: isLoading)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("🔍 DishAnalysisView appeared for dish: \(menuItem.name)")
            analyzeDish()
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
} 