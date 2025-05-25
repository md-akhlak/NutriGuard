import SwiftUI
import Supabase

// Profile Data Model
struct ProfileData: Codable {
    var id: String?
    var email: String?
    var name: String?
    var chronicConditions: [String]?
    var foodAllergies: [String]?
    var medications: [String]?
    var dietType: String?
    var permanentDislikes: [String]?
    var activityLevel: String?
    var longTermGoals: [String]?
    var age: Int?
    var gender: String?
    var height: Double?
    var weight: Double?
    var bmi: Double?
    var bloodType: String?
    var emergencyContact: String?
    var dietaryRestrictions: [String]?
    var mealPreferences: [String]?
    var cookingSkillLevel: String?
    var familyMedicalHistory: [String]?
    var previousSurgeries: [String]?
    var currentMedications: [String]?
    var sleepPattern: String?
    var stressLevel: String?
    var exerciseFrequency: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email, name
        case chronicConditions = "chronic_conditions"
        case foodAllergies = "food_allergies"
        case medications
        case dietType = "diet_type"
        case permanentDislikes = "permanent_dislikes"
        case activityLevel = "activity_level"
        case longTermGoals = "long_term_goals"
        case age, gender, height, weight, bmi
        case bloodType = "blood_type"
        case emergencyContact = "emergency_contact"
        case dietaryRestrictions = "dietary_restrictions"
        case mealPreferences = "meal_preferences"
        case cookingSkillLevel = "cooking_skill_level"
        case familyMedicalHistory = "family_medical_history"
        case previousSurgeries = "previous_surgeries"
        case currentMedications = "current_medications"
        case sleepPattern = "sleep_pattern"
        case stressLevel = "stress_level"
        case exerciseFrequency = "exercise_frequency"
    }
}

class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var isNewUser = false
    @Published var showHealthForm = false
    @Published var userName: String = ""
    
    // Health Profile Data
    @Published var healthProfile = HealthProfile()
    
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://pyydxlnkurwqzpsrdkkl.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB5eWR4bG5rdXJ3cXpwc3Jka2tsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxNTMyMzgsImV4cCI6MjA2MzcyOTIzOH0.tfhSCacWbwAL4ATBAM2lDLYJ-JaHk27W7jW64O6ymNk"
    )
    
    init() {}
    
    func signIn() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let session = try await supabase.auth.signIn(
                    email: email,
                    password: password
                )
                
                // Get user profile from Supabase
                let user = session.user
                let response = try await supabase
                    .database
                    .from("profiles")
                    .select()
                    .eq("id", value: user.id.uuidString)
                    .single()
                    .execute()
                
                // Handle the response data
                if let profile = try? response.value as? ProfileData {
                    DispatchQueue.main.async {
                        self.userName = profile.name ?? "User"
                        self.healthProfile = HealthProfile(from: profile)
                        self.isLoading = false
                        self.isAuthenticated = true
                    }
                } else {
                    DispatchQueue.main.async {
                        self.userName = "User"
                        self.isLoading = false
                        self.isAuthenticated = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signUp() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let session = try await supabase.auth.signUp(
                    email: email,
                    password: password
                )
                
                // Create initial profile with just email
                let initialProfile = ProfileData(
                    id: session.user.id.uuidString,
                    email: email,
                    name: userName
                )
                
                try await supabase
                    .database
                    .from("profiles")
                    .insert(initialProfile)
                    .execute()
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isNewUser = true
                    self.showHealthForm = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func submitHealthForm() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Get the current user ID
                let session = try await supabase.auth.session
                let userId = session.user.id.uuidString
                
                print("Submitting health form for user: \(userId)")
                
                let profileData = ProfileData(
                    id: userId,
                    chronicConditions: healthProfile.chronicConditions,
                    foodAllergies: healthProfile.foodAllergies,
                    medications: healthProfile.medications,
                    dietType: healthProfile.dietType,
                    permanentDislikes: healthProfile.permanentDislikes,
                    activityLevel: healthProfile.activityLevel,
                    longTermGoals: healthProfile.longTermGoals,
                    age: healthProfile.age,
                    gender: healthProfile.gender,
                    height: healthProfile.height,
                    weight: healthProfile.weight,
                    bmi: healthProfile.bmi,
                    bloodType: healthProfile.bloodType,
                    emergencyContact: healthProfile.emergencyContact,
                    dietaryRestrictions: healthProfile.dietaryRestrictions,
                    mealPreferences: healthProfile.mealPreferences,
                    cookingSkillLevel: healthProfile.cookingSkillLevel,
                    familyMedicalHistory: healthProfile.familyMedicalHistory,
                    previousSurgeries: healthProfile.previousSurgeries,
                    currentMedications: healthProfile.currentMedications,
                    sleepPattern: healthProfile.sleepPattern,
                    stressLevel: healthProfile.stressLevel,
                    exerciseFrequency: healthProfile.exerciseFrequency
                )
                
                print("Profile data to be updated: \(profileData)")
                
                // First, verify the profile exists
                let checkResponse = try await supabase
                    .database
                    .from("profiles")
                    .select()
                    .eq("id", value: userId)
                    .single()
                    .execute()
                
                print("Profile check response: \(checkResponse)")
                
                // Update the profile
                let updateResponse = try await supabase
                    .database
                    .from("profiles")
                    .update(profileData)
                    .eq("id", value: userId)
                    .execute()
                
                print("Update response: \(updateResponse)")
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showHealthForm = false
                    self.isAuthenticated = true
                }
            } catch {
                print("Error updating profile: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func updateProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let session = try await supabase.auth.session
                let userId = session.user.id.uuidString
                
                let profileData = ProfileData(
                    id: userId,
                    name: userName,
                    chronicConditions: healthProfile.chronicConditions,
                    foodAllergies: healthProfile.foodAllergies,
                    medications: healthProfile.medications,
                    dietType: healthProfile.dietType,
                    permanentDislikes: healthProfile.permanentDislikes,
                    activityLevel: healthProfile.activityLevel,
                    longTermGoals: healthProfile.longTermGoals,
                    age: healthProfile.age,
                    gender: healthProfile.gender,
                    height: healthProfile.height,
                    weight: healthProfile.weight,
                    bmi: healthProfile.bmi,
                    bloodType: healthProfile.bloodType,
                    emergencyContact: healthProfile.emergencyContact,
                    dietaryRestrictions: healthProfile.dietaryRestrictions,
                    mealPreferences: healthProfile.mealPreferences,
                    cookingSkillLevel: healthProfile.cookingSkillLevel,
                    familyMedicalHistory: healthProfile.familyMedicalHistory,
                    previousSurgeries: healthProfile.previousSurgeries,
                    currentMedications: healthProfile.currentMedications,
                    sleepPattern: healthProfile.sleepPattern,
                    stressLevel: healthProfile.stressLevel,
                    exerciseFrequency: healthProfile.exerciseFrequency
                )
                
                try await supabase
                    .database
                    .from("profiles")
                    .update(profileData)
                    .eq("id", value: userId)
                    .execute()
                
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signOut() {
        Task {
            do {
                try await supabase.auth.signOut()
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.userName = ""
                    self.healthProfile = HealthProfile()
                    self.showHealthForm = false
                }
            } catch {
                print("Error signing out: \(error)")
            }
        }
    }
}

// Health Profile Model
struct HealthProfile {
    var chronicConditions: [String] = []
    var foodAllergies: [String] = []
    var medications: [String] = []
    var dietType: String = ""
    var permanentDislikes: [String] = []
    var activityLevel: String = ""
    var longTermGoals: [String] = []
    var age: Int = 0
    var gender: String = ""
    var height: Double = 0.0
    var weight: Double = 0.0
    var bmi: Double = 0.0
    var bloodType: String = ""
    var emergencyContact: String = ""
    var dietaryRestrictions: [String] = []
    var mealPreferences: [String] = []
    var cookingSkillLevel: String = ""
    var familyMedicalHistory: [String] = []
    var previousSurgeries: [String] = []
    var currentMedications: [String] = []
    var sleepPattern: String = ""
    var stressLevel: String = ""
    var exerciseFrequency: String = ""
    
    init() {}
    
    init(from profile: ProfileData) {
        self.chronicConditions = profile.chronicConditions ?? []
        self.foodAllergies = profile.foodAllergies ?? []
        self.medications = profile.medications ?? []
        self.dietType = profile.dietType ?? ""
        self.permanentDislikes = profile.permanentDislikes ?? []
        self.activityLevel = profile.activityLevel ?? ""
        self.longTermGoals = profile.longTermGoals ?? []
        self.age = profile.age ?? 0
        self.gender = profile.gender ?? ""
        self.height = profile.height ?? 0.0
        self.weight = profile.weight ?? 0.0
        self.bmi = profile.bmi ?? 0.0
        self.bloodType = profile.bloodType ?? ""
        self.emergencyContact = profile.emergencyContact ?? ""
        self.dietaryRestrictions = profile.dietaryRestrictions ?? []
        self.mealPreferences = profile.mealPreferences ?? []
        self.cookingSkillLevel = profile.cookingSkillLevel ?? ""
        self.familyMedicalHistory = profile.familyMedicalHistory ?? []
        self.previousSurgeries = profile.previousSurgeries ?? []
        self.currentMedications = profile.currentMedications ?? []
        self.sleepPattern = profile.sleepPattern ?? ""
        self.stressLevel = profile.stressLevel ?? ""
        self.exerciseFrequency = profile.exerciseFrequency ?? ""
    }
} 
