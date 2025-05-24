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
}

struct MenuAnalysisView: View {
    @Environment(\.colorScheme) var colorScheme
    let menuImage: UIImage
    @State private var menuItems: [MenuItem] = []
    @State private var isAnalyzing = true
    @State private var selectedCuisine: String = "All"
    @State private var selectedHealthFilter: String = "All"
    @State private var errorMessage: String?
    let cuisines = ["All", "Italian", "Mexican", "Indian", "Chinese", "Japanese", "American"]
    let healthFilters = ["All", "Diabetes", "Hypertension", "Heart Disease", "Gluten Sensitivity"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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
                
                // Filters
                VStack(spacing: 15) {
                    // Cuisine Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(cuisines, id: \.self) { cuisine in
                                Button(action: {
                                    selectedCuisine = cuisine
                                }) {
                                    Text(cuisine)
                                        .padding(.horizontal, 15)
                                        .padding(.vertical, 8)
                                        .background(selectedCuisine == cuisine ? Color.red : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedCuisine == cuisine ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Health Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(healthFilters, id: \.self) { filter in
                                Button(action: {
                                    selectedHealthFilter = filter
                                }) {
                                    Text(filter)
                                        .padding(.horizontal, 15)
                                        .padding(.vertical, 8)
                                        .background(selectedHealthFilter == filter ? Color.green : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedHealthFilter == filter ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
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
                    // Menu Items
                    LazyVStack(spacing: 15) {
                        ForEach(filteredMenuItems) { item in
                            MenuItemCard(item: item)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            analyzeMenu()
        }
    }
    
    private var filteredMenuItems: [MenuItem] {
        var filtered = menuItems
        if selectedCuisine != "All" {
            filtered = filtered.filter { $0.cuisine == selectedCuisine }
        }
        if selectedHealthFilter != "All" {
            filtered = filtered.filter { $0.healthImpacts.contains { $0.condition == selectedHealthFilter } }
        }
        return filtered
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

struct MenuItemCard: View {
    @Environment(\.colorScheme) var colorScheme
    let item: MenuItem
    @State private var showHealthDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                    Text(item.cuisine)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(item.price)
                    .font(.headline)
                    .foregroundColor(.red)
            }
            
            // Rating and Health Score
            HStack {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", item.rating))
                }
                
                Spacer()
                
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("Health Score: \(item.healthScore)%")
                }
            }
            
            // Allergens
            if !item.allergens.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(item.allergens, id: \.self) { allergen in
                            Text(allergen)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            
            // Nutritional Info
            VStack(alignment: .leading, spacing: 8) {
                Text("Nutritional Information")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    ForEach(Array(item.nutritionalInfo.keys.sorted()), id: \.self) { key in
                        VStack {
                            Text(key)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(item.nutritionalInfo[key] ?? "")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        if key != item.nutritionalInfo.keys.sorted().last {
                            Spacer()
                        }
                    }
                }
            }
            
            // Health Impact Button
            Button(action: {
                withAnimation {
                    showHealthDetails.toggle()
                }
            }) {
                HStack {
                    Text("View Health Impact")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Image(systemName: showHealthDetails ? "chevron.up" : "chevron.down")
                }
                .foregroundColor(.blue)
            }
            
            if showHealthDetails {
                // Health Impacts
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(item.healthImpacts) { impact in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(impact.condition)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(impact.severity.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(impact.severity.color.opacity(0.2))
                                    .foregroundColor(impact.severity.color)
                                    .cornerRadius(8)
                            }
                            
                            Text(impact.impact)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(impact.recommendation)
                                .font(.caption)
                                .foregroundColor(impact.severity.color)
                        }
                        .padding(.vertical, 5)
                    }
                }
                .padding(.vertical, 5)
                
                // Dietary Benefits and Concerns
                HStack(alignment: .top, spacing: 15) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Benefits")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        ForEach(item.dietaryBenefits, id: \.self) { benefit in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(benefit)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Concerns")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        ForEach(item.dietaryConcerns, id: \.self) { concern in
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.orange)
                                Text(concern)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding(.vertical, 5)
                
                // Alternative Options
                VStack(alignment: .leading, spacing: 5) {
                    Text("Alternative Options")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    ForEach(item.alternativeOptions, id: \.self) { option in
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.blue)
                            Text(option)
                                .font(.caption)
                        }
                    }
                }
                .padding(.vertical, 5)
            }
            
            // Recommendation
            Text(item.recommendation)
                .font(.subheadline)
                .foregroundColor(.green)
                .padding(.top, 5)
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

#Preview {
    MenuAnalysisView(menuImage: UIImage())
} 