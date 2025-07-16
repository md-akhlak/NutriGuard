import SwiftUI

struct MenuAnalysisView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    let menuImage: UIImage
    @State private var menuItems: [MenuItem] = []
    @State private var isAnalyzing = true
    @State private var selectedCuisine: String = "All"
    @State private var selectedHealthFilter: String = "All"
    @State private var errorMessage: String?
    @State private var showProfileSetup = false
    @State private var searchText = ""
    let cuisines = ["All", "Italian", "Mexican", "Indian", "Chinese", "Japanese", "American"]
    let healthFilters = ["All", "Diabetes", "Hypertension", "Heart Disease", "Gluten Sensitivity"]
    
    var filteredItems: [MenuItem] {
        var items = menuItems
        
        // Apply cuisine filter
        if selectedCuisine != "All" {
            items = items.filter { $0.cuisine == selectedCuisine }
        }
        
        // Apply search text
        if !searchText.isEmpty {
            items = items.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        
        return items
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search menu items...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Cuisine Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(cuisines, id: \.self) { cuisine in
                            FilterButton(title: cuisine, isSelected: selectedCuisine == cuisine) {
                                withAnimation {
                                    selectedCuisine = cuisine
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 5)
                
                if isAnalyzing {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Analyzing menu items...")
                            .font(.headline)
                        Text("This may take a moment")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                            .padding()
                        Text(error)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(filteredItems) { item in
                                NavigationLink(destination: DishAnalysisView(menuItem: item)) {
                                    MenuItemCard(item: item)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // Start menu analysis
            Task {
                do {
                    let processor = MenuImageProcessor.shared
                    let items = try await processor.processMenuImage(menuImage)
                    menuItems = items
                    isAnalyzing = false
                } catch {
                    errorMessage = "Failed to analyze menu. Please try again."
                    isAnalyzing = false
                }
            }
        }
    }
}

struct MenuItemCard: View {
    let item: MenuItem
    @Environment(\.colorScheme) var colorScheme
    @State private var isLoading = true
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(item.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(item.cuisine)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack(spacing: 18) {
                    if item.nutritionalInfo["Calories"] == nil || item.nutritionalInfo["Calories"] == "Analyzing..." {
                        ShimmerBadge(icon: "flame.fill", unit: "cal")
                        ShimmerBadge(icon: "chart.pie.fill", unit: "g")
                        ShimmerBadge(icon: "leaf.fill", unit: "g")
                    } else {
                        NutritionBadge(icon: "flame.fill", value: item.nutritionalInfo["Calories"] ?? "-", unit: "cal")
                        NutritionBadge(icon: "chart.pie.fill", value: item.nutritionalInfo["Protein"] ?? "-", unit: "g")
                        NutritionBadge(icon: "leaf.fill", value: item.nutritionalInfo["Carbs"] ?? "-", unit: "g")
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.system(size: 18, weight: .semibold))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
        )
        .padding(.vertical, 6)
        .animation(.easeInOut, value: item.nutritionalInfo)
    }
}

struct ShimmerBadge: View {
    let icon: String
    let unit: String
    @State private var shimmer = false
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(.red.gradient)
                .opacity(shimmer ? 0.5 : 1)
                .animation(Animation.linear(duration: 1).repeatForever(autoreverses: true), value: shimmer)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 12)
                .shimmering(active: shimmer)
            Text(unit)
                .foregroundColor(.secondary)
        }
        .font(.caption)
        .onAppear { shimmer = true }
    }
}

extension View {
    func shimmering(active: Bool) -> some View {
        self.overlay(
            GeometryReader { geometry in
                if active {
                    LinearGradient(gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.6), Color.clear]), startPoint: .leading, endPoint: .trailing)
                        .rotationEffect(.degrees(30))
                        .offset(x: active ? geometry.size.width : -geometry.size.width)
                        .animation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false), value: active)
                }
            }
        )
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(isSelected ? Color.red.gradient : Color.gray.opacity(0.15).gradient)
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .shadow(color: isSelected ? .red.opacity(0.18) : .clear, radius: 6, x: 0, y: 3)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 15) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Analyzing menu...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

struct ErrorView: View {
    let error: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text(error)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                retryAction()
            }
            .padding()
            .background(Color.blue.gradient)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .padding()
    }
}

struct EmptyStateView: View {
    var body: some View {
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
    }
}

struct MenuItemsTable: View {
    let items: [MenuItem]
    @State private var expandedItem: MenuItem?
    @State private var selectedItem: MenuItem?
    
    var body: some View {
        LazyVStack(spacing: 15) {
            ForEach(items) { item in
                NavigationLink(destination: DishAnalysisView(menuItem: item)) {
                    MenuItemRow(item: item)
                }
            }
        }
        .padding()
    }
}

struct MenuItemRow: View {
    let item: MenuItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(item.cuisine)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            
            if !item.allergens.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(item.allergens, id: \.self) { allergen in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(allergen)
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // Quick Nutritional Info
            if !item.nutritionalInfo.isEmpty {
                HStack(spacing: 15) {
                    if let calories = item.nutritionalInfo["Calories"] {
                        NutritionBadge(icon: "flame.fill", value: calories, unit: "cal")
                    }
                    if let protein = item.nutritionalInfo["Protein"] {
                        NutritionBadge(icon: "figure.strengthtraining", value: protein, unit: "g")
                    }
                    if let carbs = item.nutritionalInfo["Carbs"] {
                        NutritionBadge(icon: "leaf.fill", value: carbs, unit: "g")
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(radius: 5)
    }
}

struct NutritionBadge: View {
    let icon: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(.red.gradient)
            Text(value)
                .fontWeight(.medium)
            Text(unit)
                .foregroundColor(.secondary)
        }
        .font(.caption)
    }
}

struct ProfileSetupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var chronicConditions: [String] = []
    @State private var foodAllergies: [String] = []
    @State private var dietType: String = "Regular"
    @State private var activityLevel: String = "Moderate"
    
    let dietTypes = ["Regular", "Vegetarian", "Vegan", "Keto", "Low-Carb", "Low-Sodium", "Gluten-Free"]
    let activityLevels = ["Sedentary", "Light", "Moderate", "Active", "Very Active"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Chronic Conditions")) {
                    ForEach(chronicConditions, id: \.self) { condition in
                        Text(condition)
                    }
                    Button("Add Condition") {
                        // Add condition logic
                    }
                }
                
                Section(header: Text("Food Allergies")) {
                    ForEach(foodAllergies, id: \.self) { allergy in
                        Text(allergy)
                    }
                    Button("Add Allergy") {
                        // Add allergy logic
                    }
                }
                
                Section(header: Text("Diet Type")) {
                    Picker("Diet Type", selection: $dietType) {
                        ForEach(dietTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Activity Level")) {
                    Picker("Activity Level", selection: $activityLevel) {
                        ForEach(activityLevels, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                }
            }
            .navigationTitle("Health Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveProfile()
                    dismiss()
                }
            )
        }
    }
    
    private func saveProfile() {
        let profile = UserHealthProfile(
            chronicConditions: chronicConditions,
            foodAllergies: foodAllergies,
            medications: [],
            dietType: dietType,
            permanentDislikes: [],
            activityLevel: activityLevel,
            longTermGoals: ["Maintain healthy diet"]
        )
        UserProfileManager.shared.userProfile = profile
    }
}

#Preview {
    MenuAnalysisView(menuImage: UIImage())
} 
