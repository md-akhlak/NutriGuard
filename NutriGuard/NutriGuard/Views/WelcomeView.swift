import SwiftUI

struct WelcomeView: View {
    @ObservedObject var userProfile: UserProfile
    @State private var name = ""
    @State private var selectedConditions: Set<MedicalCondition> = []
    @State private var additionalRestrictions: [String] = []
    @State private var currentStep = 0
    @State private var newRestriction = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var shouldNavigateToMain = false
    
    var body: some View {
        NavigationView {
            VStack {
                TabView(selection: $currentStep) {
                    // Welcome Screen
                    welcomeScreen
                        .tag(0)
                    
                    // Personal Info
                    personalInfoScreen
                        .tag(1)
                    
                    // Medical Conditions
                    medicalConditionsScreen
                        .tag(2)
                    
                    // Additional Restrictions
                    additionalRestrictionsScreen
                        .tag(3)
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Progress Bar
                ProgressBar(currentStep: currentStep, totalSteps: 4)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                // Navigation Buttons
                HStack {
                    if currentStep > 0 {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(.blue)
                            .padding()
                        }
                    }
                    
                    Spacer()
                    
                    if currentStep < 3 {
                        Button(action: {
                            withAnimation {
                                currentStep += 1
                            }
                        }) {
                            HStack {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(name.isEmpty && currentStep == 1 ? Color.gray : Color.blue)
                            .cornerRadius(10)
                        }
                        .disabled(currentStep == 1 && name.isEmpty)
                    } else {
                        Button(action: {
                            saveProfile()
                            hasCompletedOnboarding = true
                            shouldNavigateToMain = true
                        }) {
                            Text("Get Started")
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 200)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                        .disabled(name.isEmpty)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $shouldNavigateToMain) {
                ContentView()
                    .environmentObject(userProfile)
            }
        }
    }
    
    private var welcomeScreen: some View {
        VStack(spacing: 25) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.linearGradient(
                    colors: [.green, .blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
            
            Text("Welcome to NutriGuard")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Eat Smart. Live Safe.")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Let's set up your profile to help you make safe food choices")
                .multilineTextAlignment(.center)
                .padding()
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var personalInfoScreen: some View {
        VStack(spacing: 25) {
            Text("Tell us about yourself")
                .font(.title)
                .fontWeight(.bold)
            
            Text("We'll use this to personalize your experience")
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Name")
                    .foregroundColor(.secondary)
                TextField("Enter your name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .frame(maxWidth: 300)
            }
            .padding()
        }
        .padding()
    }
    
    private var medicalConditionsScreen: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Medical Conditions")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text("Select all that apply to you:")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(MedicalCondition.allCases) { condition in
                        ConditionCard(
                            condition: condition,
                            isSelected: selectedConditions.contains(condition)
                        ) {
                            withAnimation {
                                if selectedConditions.contains(condition) {
                                    selectedConditions.remove(condition)
                                } else {
                                    selectedConditions.insert(condition)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private var additionalRestrictionsScreen: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Additional Restrictions")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text("Add any other dietary restrictions:")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
            
            HStack {
                TextField("Enter restriction", text: $newRestriction)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    if !newRestriction.isEmpty {
                        additionalRestrictions.append(newRestriction)
                        newRestriction = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
                    ForEach(additionalRestrictions, id: \.self) { restriction in
                        HStack {
                            Text(restriction)
                            Spacer()
                            Button(action: {
                                additionalRestrictions.removeAll { $0 == restriction }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
    }
    
    private func saveProfile() {
        userProfile.name = name
        userProfile.medicalConditions = selectedConditions
        userProfile.additionalRestrictions = additionalRestrictions
    }
}

struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color.secondary.opacity(0.3))
                    .frame(width: geometry.size.width, height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .foregroundColor(.blue)
                    .frame(width: geometry.size.width * CGFloat(Double(currentStep + 1) / Double(totalSteps)), height: 8)
                    .cornerRadius(4)
                    .animation(.easeInOut, value: currentStep)
            }
        }
        .frame(height: 8)
    }
}

struct ConditionCard: View {
    let condition: MedicalCondition
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: conditionIcon)
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(condition.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private var conditionIcon: String {
        switch condition {
        case .diabetes:
            return "drop.fill"
        case .hypertension:
            return "heart.fill"
        case .celiacDisease:
            return "allergens"
        case .lactoseIntolerance:
            return "cup.and.saucer.fill"
        case .nutAllergy:
            return "leaf.fill"
        case .shellfishAllergy:
            return "fish.fill"
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(userProfile: UserProfile())
    }
} 