import SwiftUI

struct DishAnalysisView: View {
    @State var menuItem: MenuItem
    @State private var analysis: HealthAnalysis?
    @State private var isLoading = true
    @State private var error: Error?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Text(menuItem.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(menuItem.cuisine)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                    VStack(spacing: 15) {
                        HStack {
                            Image(systemName: analysis.isHealthy ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(analysis.isHealthy ? .green : .red)
                            Text(analysis.isHealthy ? "Healthy Choice" : "Consider Alternatives")
                                .font(.headline)
                                .foregroundColor(analysis.isHealthy ? .green : .red)
                        }
                        
                        Text(analysis.reason)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    
                    // Health Impacts
                    if !analysis.healthImpacts.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Health Impacts")
                                .font(.headline)
                            
                            ForEach(analysis.healthImpacts, id: \.self) { impact in
                                HStack(alignment: .top) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.orange)
                                    Text(impact)
                                        .font(.body)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    }
                    
                    // Recommendations
                    if !analysis.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Recommendations")
                                .font(.headline)
                            
                            ForEach(analysis.recommendations, id: \.self) { recommendation in
                                HStack(alignment: .top) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.blue)
                                    Text(recommendation)
                                        .font(.body)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    }
                    
                    // Allergens
                    if !menuItem.allergens.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Allergens")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(menuItem.allergens, id: \.self) { allergen in
                                        Text(allergen)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.red.opacity(0.1))
                                            .foregroundColor(.red)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    }
                    
                    // Nutritional Information
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Nutritional Information")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            ForEach(Array(menuItem.nutritionalInfo.keys.sorted()), id: \.self) { key in
                                VStack {
                                    Text(key)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(menuItem.nutritionalInfo[key] ?? "")
                                        .font(.headline)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    
                    // Alternative Options
                    if !menuItem.alternativeOptions.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Alternative Options")
                                .font(.headline)
                            
                            ForEach(menuItem.alternativeOptions, id: \.self) { option in
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.blue)
                                    Text(option)
                                        .font(.body)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("🔍 DishAnalysisView appeared for dish: \(menuItem.name)")
            analyzeDish()
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
    
    private func analyzeHealthImpact(for condition: String, dishText: String) -> (impact: String, recommendation: String, severity: ImpactSeverity) {
        switch condition.lowercased() {
        case "diabetes":
            if dishText.contains("sugar") || dishText.contains("sweet") {
                return (
                    "High sugar content may affect blood sugar levels",
                    "Consider sugar-free alternatives or smaller portions",
                    .negative
                )
            } else if dishText.contains("whole grain") || dishText.contains("fiber") {
                return (
                    "Good source of fiber and complex carbohydrates",
                    "This is a good choice for diabetes management",
                    .positive
                )
            }
            // Check carb content
            if let carbs = extractNumericValue(from: dishText, key: "carbs"), carbs > 45 {
                return (
                    "High carbohydrate content may affect blood sugar",
                    "Consider reducing portion size or choosing lower-carb options",
                    .negative
                )
            }
            return (
                "Moderate impact on blood sugar",
                "Monitor portion size and pair with protein",
                .neutral
            )
            
        case "hypertension":
            if dishText.contains("salt") || dishText.contains("sodium") {
                return (
                    "High sodium content may affect blood pressure",
                    "Request low-sodium preparation or smaller portions",
                    .negative
                )
            } else if dishText.contains("low sodium") || dishText.contains("unsalted") {
                return (
                    "Low sodium content is good for blood pressure",
                    "This is a good choice for hypertension management",
                    .positive
                )
            }
            // Check sodium content
            if let sodium = extractNumericValue(from: dishText, key: "sodium"), sodium > 600 {
                return (
                    "High sodium content exceeds recommended limits",
                    "Consider low-sodium alternatives or half portions",
                    .negative
                )
            }
            return (
                "Moderate sodium content",
                "Monitor portion size and avoid adding extra salt",
                .neutral
            )
            
        case "heart disease":
            if dishText.contains("fried") || dishText.contains("fatty") {
                return (
                    "High in saturated fats may affect heart health",
                    "Consider grilled or baked alternatives",
                    .negative
                )
            } else if dishText.contains("grilled") || dishText.contains("baked") {
                return (
                    "Low in saturated fats, good for heart health",
                    "This is a good choice for heart health",
                    .positive
                )
            }
            // Check fat content
            if let fat = extractNumericValue(from: dishText, key: "fat"), fat > 20 {
                return (
                    "High fat content may impact heart health",
                    "Consider leaner options or smaller portions",
                    .negative
                )
            }
            return (
                "Moderate impact on heart health",
                "Monitor portion size and fat content",
                .neutral
            )
            
        default:
            // General health analysis based on nutritional values
            if let calories = extractNumericValue(from: dishText, key: "calories"), calories > 500 {
                return (
                    "High calorie content",
                    "Consider sharing or saving half for later",
                    .negative
                )
            }
            return (
                "General health impact",
                "Consider your overall dietary needs",
                .neutral
            )
        }
    }

    private func extractNumericValue(from text: String, key: String) -> Double? {
        let pattern = "\(key)[^0-9]*([0-9]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        guard let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) else { return nil }
        guard let range = Range(match.range(at: 1), in: text) else { return nil }
        return Double(text[range])
    }
} 