import SwiftUI

struct PatientFormView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var currentStep = 0
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Basic Information
    @State private var name = ""
    @State private var age = ""
    @State private var gender = ""
    
    // One-Time Details
    @State private var chronicConditions: [String] = []
    @State private var foodAllergies: [String] = []
    @State private var medications: [String] = []
    @State private var labMetrics: [String] = []
    @State private var dietType = ""
    @State private var permanentDislikes: [String] = []
    @State private var activityLevel = ""
    @State private var longTermGoals: [String] = []
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress Bar
                ProgressView(value: Double(currentStep), total: 4)
                    .padding()
                    .tint(.red)
                
                // Step Indicator
                HStack {
                    ForEach(0..<4) { step in
                        Circle()
                            .fill(step <= currentStep ? Color.red : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.bottom)
                
                // Step Content
                TabView(selection: $currentStep) {
                    // Step 1: Basic Information
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Basic Information 👤")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 15) {
                            CustomTextField(text: $name, placeholder: "Full Name")
                            CustomTextField(text: $age, placeholder: "Age", keyboardType: .numberPad)
                            SingleDropdownField(title: "Gender", items: ["Male", "Female", "Other", "Prefer not to say"], selectedItem: $gender)
                        }
                        
                        Spacer()
                        
                        NavigationButton(title: "Next", action: {
                            withAnimation {
                                currentStep = 1
                            }
                        })
                    }
                    .padding()
                    .tag(0)
                    
                    // Step 2: Medical Profile
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Medical Profile 🏥")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        DropdownField(title: "Chronic Conditions", items: ["Diabetes", "Hypertension", "Heart Disease", "None"], selectedItems: $chronicConditions)
                        DropdownField(title: "Food Allergies", items: ["Gluten", "Dairy", "Nuts", "None"], selectedItems: $foodAllergies)
                        DropdownField(title: "Medications", items: ["Insulin", "Blood Thinners", "None"], selectedItems: $medications)
                        
                        Spacer()
                        
                        HStack {
                            NavigationButton(title: "Back", action: {
                                withAnimation {
                                    currentStep = 0
                                }
                            })
                            
                            NavigationButton(title: "Next", action: {
                                withAnimation {
                                    currentStep = 2
                                }
                            })
                        }
                    }
                    .padding()
                    .tag(1)
                    
                    // Step 3: Dietary Preferences
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Dietary Preferences 🥗")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        SingleDropdownField(title: "Diet Type", items: ["Keto", "Vegan", "Low-Sodium", "None"], selectedItem: $dietType)
                        DropdownField(title: "Permanent Dislikes", items: ["Shellfish", "Cilantro", "None"], selectedItems: $permanentDislikes)
                        
                        Spacer()
                        
                        HStack {
                            NavigationButton(title: "Back", action: {
                                withAnimation {
                                    currentStep = 1
                                }
                            })
                            
                            NavigationButton(title: "Next", action: {
                                withAnimation {
                                    currentStep = 3
                                }
                            })
                        }
                    }
                    .padding()
                    .tag(2)
                    
                    // Step 4: Lifestyle
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Lifestyle Basics 🏃‍♂️")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        SingleDropdownField(title: "Activity Level", items: ["Sedentary", "Moderately Active", "Very Active"], selectedItem: $activityLevel)
                        DropdownField(title: "Long-Term Goals", items: ["Weight Loss", "Muscle Gain", "Maintenance", "None"], selectedItems: $longTermGoals)
                        
                        Spacer()
                        
                        HStack {
                            NavigationButton(title: "Back", action: {
                                withAnimation {
                                    currentStep = 2
                                }
                            })
                            
                            NavigationButton(title: "Finish", action: {
                                submitForm()
                            })
                        }
                    }
                    .padding()
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationBarTitle("NutriGuard", displayMode: .inline)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func submitForm() {
        // Update AuthViewModel's health profile with form data
        authViewModel.userName = name
        authViewModel.healthProfile.age = Int(age) ?? 0
        authViewModel.healthProfile.gender = gender
        authViewModel.healthProfile.chronicConditions = chronicConditions
        authViewModel.healthProfile.foodAllergies = foodAllergies
        authViewModel.healthProfile.medications = medications
        authViewModel.healthProfile.dietType = dietType
        authViewModel.healthProfile.permanentDislikes = permanentDislikes
        authViewModel.healthProfile.activityLevel = activityLevel
        authViewModel.healthProfile.longTermGoals = longTermGoals
        
        // Submit the form data to Supabase
        authViewModel.submitHealthForm()
        
        // Navigate to HomeView
        let homeView = HomeView()
            .environmentObject(authViewModel)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UIHostingController(rootView: homeView)
        }
    }
}

struct CustomTextField: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
    }
}

struct SingleDropdownField: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let items: [String]
    @Binding var selectedItem: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            DisclosureGroup(
                isExpanded: $isExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(items, id: \.self) { item in
                            Button(action: {
                                selectedItem = item
                                withAnimation {
                                    isExpanded = false
                                }
                            }) {
                                HStack {
                                    Text(item)
                                    Spacer()
                                    if selectedItem == item {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 8)
                },
                label: {
                    Text(selectedItem.isEmpty ? "Select \(title)" : selectedItem)
                        .foregroundColor(selectedItem.isEmpty ? .secondary : .primary)
                }
            )
            .buttonStyle(PlainButtonStyle())
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct DropdownField: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let items: [String]
    @Binding var selectedItems: [String]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            DisclosureGroup(
                isExpanded: $isExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(items, id: \.self) { item in
                            Button(action: {
                                if selectedItems.contains(item) {
                                    selectedItems.removeAll { $0 == item }
                                } else {
                                    selectedItems.append(item)
                                }
                                withAnimation {
                                    isExpanded = false
                                }
                            }) {
                                HStack {
                                    Text(item)
                                    Spacer()
                                    if selectedItems.contains(item) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 8)
                },
                label: {
                    Text(selectedItems.isEmpty ? "Select \(title)" : selectedItems.joined(separator: ", "))
                        .foregroundColor(selectedItems.isEmpty ? .secondary : .primary)
                }
            )
            .buttonStyle(PlainButtonStyle())
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct NavigationButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
        }
    }
}

struct FormSection<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
                .padding()
                .background(colorScheme == .dark ? Color(.systemGray6) : .white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

#Preview {
    PatientFormView()
} 
