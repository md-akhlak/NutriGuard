import SwiftUI
import VisionKit

struct MenuAnalysisView: View {
    @ObservedObject var viewModel: MenuScannerViewModel
    @ObservedObject var userProfile: UserProfile
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            if viewModel.analyzedItems.isEmpty {
                ContentUnavailableView {
                    Label {
                        Text("No Menu Items")
                            .font(.title2)
                            .fontWeight(.bold)
                    } icon: {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundStyle(.linearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                    }
                } description: {
                    Text("Scan a menu to see personalized analysis")
                        .foregroundColor(.secondary)
                } actions: {
                    Button(action: { viewModel.clearScan() }) {
                        HStack {
                            Image(systemName: "doc.viewfinder")
                            Text("Start Scanning")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Summary Card
                        AnalysisSummaryCard(items: viewModel.analyzedItems)
                            .padding(.horizontal)
                        
                        // Items List
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Detailed Analysis")
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.analyzedItems, id: \.name) { item in
                                MenuAnalysisDetailRow(item: item, userProfile: userProfile)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Menu Analysis")
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct MenuAnalysisDetailRow: View {
    let item: (name: String, safety: FoodSafetyLevel)
    @ObservedObject var userProfile: UserProfile
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name)
                            .font(.headline)
                        
                        if item.safety != .safe {
                            Text("Contains restricted ingredients")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    SafetyIndicator(safety: item.safety)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.spring(), value: isExpanded)
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    if item.safety != .safe {
                        Text("Warnings")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        
                        ForEach(userProfile.getAllRestrictions(), id: \.self) { restriction in
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                Text(restriction.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    Text("Recommendations")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(safetyRecommendation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
            }
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private var safetyRecommendation: String {
        switch item.safety {
        case .safe:
            return "This item appears to be safe based on your dietary restrictions."
        case .caution:
            return "Exercise caution with this item. Consider asking the staff about specific ingredients."
        case .unsafe:
            return "This item contains ingredients that conflict with your dietary restrictions. We recommend avoiding it."
        }
    }
}

struct AnalysisSummaryCard: View {
    let items: [(name: String, safety: FoodSafetyLevel)]
    
    private var safeCount: Int {
        items.filter { $0.safety == .safe }.count
    }
    
    private var cautionCount: Int {
        items.filter { $0.safety == .caution }.count
    }
    
    private var unsafeCount: Int {
        items.filter { $0.safety == .unsafe }.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Analysis Summary")
                .font(.headline)
            
            HStack(spacing: 20) {
                SummaryItem(count: safeCount, label: "Safe", color: .green)
                SummaryItem(count: cautionCount, label: "Caution", color: .yellow)
                SummaryItem(count: unsafeCount, label: "Unsafe", color: .red)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct SummaryItem: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SafetyIndicator: View {
    let safety: FoodSafetyLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(safetyColor)
                .frame(width: 8, height: 8)
            
            Text(safetyText)
                .font(.caption)
                .foregroundColor(safetyColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(safetyColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var safetyColor: Color {
        switch safety {
        case .safe:
            return .green
        case .caution:
            return .yellow
        case .unsafe:
            return .red
        }
    }
    
    private var safetyText: String {
        switch safety {
        case .safe:
            return "Safe"
        case .caution:
            return "Caution"
        case .unsafe:
            return "Unsafe"
        }
    }
}

struct FoodItemView: View {
    let item: FoodItem
    let userProfile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(item.name)
                    .font(.headline)
                Spacer()
                SafetyIndicator(safety: determineSafetyLevel())
            }
            
            Text(item.description)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if determineSafetyLevel() != .safe {
                VStack(alignment: .leading) {
                    Text("Warnings:")
                        .font(.subheadline)
                        .foregroundColor(.red)
                    
                    ForEach(item.getSafetyWarnings(profile: userProfile), id: \.self) { warning in
                        Text("• \(warning)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            NutritionalInfoView(info: item.nutritionalInfo)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private func determineSafetyLevel() -> FoodSafetyLevel {
        let warnings = item.getSafetyWarnings(profile: userProfile)
        if warnings.isEmpty {
            return .safe
        }
        
        // Check for direct allergen matches (high risk)
        let allergens = item.nutritionalInfo.allergens.map { $0.lowercased() }
        let userRestrictions = userProfile.getAllRestrictions().map { $0.lowercased() }
        
        for allergen in allergens {
            if userRestrictions.contains(allergen) {
                return .unsafe
            }
        }
        
        // If we have warnings but no direct allergen matches, return caution
        return .caution
    }
}

struct NutritionalInfoView: View {
    let info: NutritionalInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Nutritional Information")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                NutrientItem(label: "Calories", value: "\(info.calories)")
                NutrientItem(label: "Carbs", value: "\(info.carbohydrates)g")
                NutrientItem(label: "Protein", value: "\(info.proteins)g")
                NutrientItem(label: "Fat", value: "\(info.fats)g")
            }
            
            if !info.allergens.isEmpty {
                Text("Allergens: \(info.allergens.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
}

struct NutrientItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }
}


