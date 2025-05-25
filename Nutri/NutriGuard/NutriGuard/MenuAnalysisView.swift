import SwiftUI

struct HealthImpact: Identifiable {
    let id = UUID()
    let condition: String
    let impact: String
    let recommendation: String
    let severity: ImpactSeverity
}

enum ImpactSeverity: String {
    case positive = "Positive"
    case neutral = "Neutral"
    case negative = "Negative"
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .neutral: return .orange
        case .negative: return .red
        }
    }
}

struct MenuItem: Identifiable {
    let id = UUID()
    let name: String
    let cuisine: String
    let price: String
    let rating: Double
    let healthScore: Int
    let allergens: [String]
    let nutritionalInfo: [String: String]
    let recommendation: String
    let healthImpacts: [HealthImpact]
    let dietaryBenefits: [String]
    let dietaryConcerns: [String]
    let alternativeOptions: [String]
    
    var healthStatus: String {
        if healthScore >= 80 {
            return "Healthy"
        } else if healthScore >= 60 {
            return "Moderate"
        } else {
            return "Unhealthy"
        }
    }
    
    var healthStatusColor: Color {
        if healthScore >= 80 {
            return .green
        } else if healthScore >= 60 {
            return .orange
        } else {
            return .red
        }
    }
}

struct MenuAnalysisView: View {
    @Environment(\.colorScheme) var colorScheme
    let menuImage: UIImage
    @State private var menuItems: [MenuItem] = []
    @State private var isAnalyzing = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 10) {
                    Text("Menu Analysis")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Personalized recommendations based on your health profile")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                if isAnalyzing {
                    // Loading State
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Analyzing menu...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else if let error = errorMessage {
                    // Error State
                    VStack(spacing: 15) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            analyzeMenu()
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                } else if menuItems.isEmpty {
                    // No Items State
                    VStack(spacing: 15) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No menu items found")
                            .foregroundColor(.secondary)
                        Text("Please try taking a clearer photo of the menu")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    // Menu Items Table
                    List {
                        ForEach(menuItems) { item in
                            MenuItemRow(item: item)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            analyzeMenu()
        }
    }
    
    private func analyzeMenu() {
        isAnalyzing = true
        errorMessage = nil
        
        MenuImageProcessor.shared.processMenuImage(menuImage) { items in
            DispatchQueue.main.async {
                isAnalyzing = false
                if items.isEmpty {
                    errorMessage = "Unable to detect menu items. Please ensure the menu is clearly visible and well-lit."
                } else {
                    menuItems = items
                }
            }
        }
    }
}

struct MenuItemRow: View {
    let item: MenuItem
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                    Text(item.cuisine)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(item.price)
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(item.healthStatus)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.healthStatusColor.opacity(0.2))
                        .foregroundColor(item.healthStatusColor)
                        .cornerRadius(8)
                }
            }
            
            if showDetails {
                Divider()
                
                // Health Score
                HStack {
                    Text("Health Score:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(item.healthScore)%")
                        .font(.subheadline)
                        .foregroundColor(item.healthStatusColor)
                }
                
                // Allergens
                if !item.allergens.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(item.allergens, id: \.self) { allergen in
                                Text(allergen)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Recommendation
                Text(item.recommendation)
                    .font(.subheadline)
                    .foregroundColor(item.healthStatusColor)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                showDetails.toggle()
            }
        }
    }
}

#Preview {
    MenuAnalysisView(menuImage: UIImage())
} 