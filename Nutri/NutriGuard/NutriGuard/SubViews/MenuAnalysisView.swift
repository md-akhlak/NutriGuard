import SwiftUI

struct MenuAnalysisView: View {
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
    
    var body: some View {
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
            
            // Profile Setup Button
            if UserProfileManager.shared.userProfile == nil {
                Button(action: {
                    showProfileSetup = true
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                        Text("Set Up Health Profile")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search menu items...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(cuisines, id: \.self) { cuisine in
                        FilterButton(title: cuisine, isSelected: selectedCuisine == cuisine) {
                            selectedCuisine = cuisine
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 10)
            
            if isAnalyzing {
                LoadingView()
            } else if let error = errorMessage {
                ErrorView(error: error, retryAction: analyzeMenu)
            } else if menuItems.isEmpty {
                EmptyStateView()
            } else {
                MenuItemsTable(items: filteredMenuItems)
            }
        }
        .sheet(isPresented: $showProfileSetup) {
            ProfileSetupView()
        }
        .onAppear {
            // Set up default profile if none exists
            if UserProfileManager.shared.userProfile == nil {
                UserProfileManager.shared.setupDefaultProfile()
            }
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
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
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

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
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
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
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
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(items) { item in
                    MenuItemRow(item: item, isExpanded: expandedItem?.id == item.id) {
                        withAnimation {
                            if expandedItem?.id == item.id {
                                expandedItem = nil
                            } else {
                                expandedItem = item
                            }
                        }
                    }
                    .onTapGesture {
                        selectedItem = item
                    }
                }
            }
            .padding()
        }
        .sheet(item: $selectedItem) { item in
            NavigationView {
                DishAnalysisView(menuItem: item)
                    .navigationBarItems(trailing: Button("Done") {
                        selectedItem = nil
                    })
            }
        }
    }
}

struct MenuItemRow: View {
    @State var item: MenuItem
    let isExpanded: Bool
    let onTap: () -> Void
    @State private var healthAnalysis: HealthAnalysis?
    @State private var isLoadingAnalysis = false
    @State private var analysisError: Error?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Row
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.headline)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text(item.cuisine)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("")
                            .font(.headline)
                            .foregroundColor(.blue)
                        HStack {
                            Image(systemName: "")
                                .foregroundColor(.red)
                            Text("")
                                .font(.subheadline)
                        }
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            
            if isExpanded {
                Divider()
                
                // Expanded Content
                VStack(alignment: .leading, spacing: 15) {
                    // Health Analysis Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Health Analysis")
                            .font(.headline)
                        
                        if isLoadingAnalysis {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if let error = analysisError {
                            Text("Error analyzing health impact: \(error.localizedDescription)")
                                .foregroundColor(.red)
                                .font(.caption)
                        } else if let analysis = healthAnalysis {
                            HStack {
                                Image(systemName: analysis.isHealthy ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(analysis.isHealthy ? .green : .red)
                                Text(analysis.isHealthy ? "Healthy" : "Unhealthy")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(analysis.isHealthy ? .green : .red)
                            }
                            
                            Text(analysis.reason)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if !analysis.healthImpacts.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Health Impacts:")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    ForEach(analysis.healthImpacts, id: \.self) { impact in
                                        HStack {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .foregroundColor(.orange)
                                            Text(impact)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                            
                            if !analysis.recommendations.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Recommendations:")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    ForEach(analysis.recommendations, id: \.self) { recommendation in
                                        HStack {
                                            Image(systemName: "arrow.right.circle.fill")
                                                .foregroundColor(.blue)
                                            Text(recommendation)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                        } else {
                            Button("Analyze Health Impact") {
                                analyzeHealthImpact()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
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
                    
                    // Health Impacts
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
                    }
                    
                    // Benefits and Concerns
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
                    
                    // Recommendation
                    Text(item.recommendation)
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color(.systemGray6))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    private func analyzeHealthImpact() {
        guard let userProfile = MenuImageProcessor.shared.userProfile else {
            analysisError = NSError(domain: "MenuItemRow", code: -1, userInfo: [NSLocalizedDescriptionKey: "User profile not found. Please complete your health profile first."])
            return
        }
        
        isLoadingAnalysis = true
        analysisError = nil
        
        Task {
            do {
                let (analysis, nutritionalInfo) = try await GeminiService.shared.analyzeMenuItem(item, userProfile: userProfile)
                await MainActor.run {
                    self.healthAnalysis = analysis
                    var updatedItem = self.item
                    updatedItem.nutritionalInfo = nutritionalInfo
                    self.item = updatedItem
                    self.isLoadingAnalysis = false
                }
            } catch {
                await MainActor.run {
                    self.analysisError = error
                    self.isLoadingAnalysis = false
                }
            }
        }
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
