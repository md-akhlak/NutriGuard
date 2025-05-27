import SwiftUI

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct PatientFormView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var currentStep = 0
    @FocusState private var focusedField: Field?
    
    // Validation States
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    @State private var isFormValid = false
    
    enum Field {
        case name, age
    }
    
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
    
    // Validation Functions
    private func validateBasicInfo() -> Bool {
        // Name validation
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "Please enter your name"
            showValidationAlert = true
            return false
        }
        
        // Age validation
        if age.isEmpty {
            validationMessage = "Please enter your age"
            showValidationAlert = true
            return false
        }
        
        if let ageInt = Int(age) {
            if ageInt < 0 || ageInt > 120 {
                validationMessage = "Please enter a valid age between 0 and 120"
                showValidationAlert = true
                return false
            }
        } else {
            validationMessage = "Please enter a valid age"
            showValidationAlert = true
            return false
        }
        
        // Gender validation
        if gender.isEmpty {
            validationMessage = "Please select your gender"
            showValidationAlert = true
            return false
        }
        
        return true
    }
    
    private func validateMedicalProfile() -> Bool {
        // At least one chronic condition should be selected (including "None")
        if chronicConditions.isEmpty {
            validationMessage = "Please select at least one option for chronic conditions"
            showValidationAlert = true
            return false
        }
        
        // At least one food allergy should be selected (including "None")
        if foodAllergies.isEmpty {
            validationMessage = "Please select at least one option for food allergies"
            showValidationAlert = true
            return false
        }
        
        // At least one medication should be selected (including "None")
        if medications.isEmpty {
            validationMessage = "Please select at least one option for medications"
            showValidationAlert = true
            return false
        }
        
        return true
    }
    
    private func validateDietaryPreferences() -> Bool {
        // Diet type validation
        if dietType.isEmpty {
            validationMessage = "Please select a diet type"
            showValidationAlert = true
            return false
        }
        
        return true
    }
    
    private func validateLifestyle() -> Bool {
        // Activity level validation
        if activityLevel.isEmpty {
            validationMessage = "Please select an activity level"
            showValidationAlert = true
            return false
        }
        
        // Long-term goals validation
        if longTermGoals.isEmpty {
            validationMessage = "Please select at least one long-term goal"
            showValidationAlert = true
            return false
        }
        
        return true
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        focusedField = nil
                    }
                
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
                                    .focused($focusedField, equals: .name)
                                CustomTextField(text: $age, placeholder: "Age", keyboardType: .numberPad)
                                    .focused($focusedField, equals: .age)
                                SingleDropdownField(title: "Gender", items: ["Male", "Female", "Other", "Prefer not to say"], selectedItem: $gender)
                            }
                            
                            Spacer()
                            
                            NavigationButton(title: "Next", action: {
                                if validateBasicInfo() {
                                    focusedField = nil
                                    withAnimation {
                                        currentStep = 1
                                    }
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
                                    if validateMedicalProfile() {
                                        withAnimation {
                                            currentStep = 2
                                        }
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
                                    if validateDietaryPreferences() {
                                        withAnimation {
                                            currentStep = 3
                                        }
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
                                    if validateLifestyle() {
                                        // Navigate to HomeView
                                        let homeView = HomeView(userName: name)
                                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                           let window = windowScene.windows.first {
                                            window.rootViewController = UIHostingController(rootView: homeView)
                                        }
                                    }
                                })
                            }
                        }
                        .padding()
                        .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationBarTitle("NutriGuard", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .alert("Validation Error", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }
}

#Preview {
    PatientFormView()
} 
