import Foundation

class UserProfileManager {
    static let shared = UserProfileManager()
    
    private init() {
        // Load saved profile if exists
        loadProfile()
    }
    
    private var _userProfile: UserHealthProfile?
    
    var userProfile: UserHealthProfile? {
        get { return _userProfile }
        set {
            _userProfile = newValue
            saveProfile()
            // Update MenuImageProcessor
            if let profile = newValue {
                MenuImageProcessor.shared.setUserProfile(profile)
            }
        }
    }
    
    func setupDefaultProfile() {
        // Create a default profile with common health conditions
        let defaultProfile = UserHealthProfile(
            chronicConditions: ["None"],
            foodAllergies: ["None"],
            medications: ["None"],
            dietType: "Regular",
            permanentDislikes: ["None"],
            activityLevel: "Moderate",
            longTermGoals: ["Maintain healthy diet"]
        )
        
        userProfile = defaultProfile
    }
    
    private func saveProfile() {
        if let profile = _userProfile,
           let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "userHealthProfile")
        }
    }
    
    private func loadProfile() {
        if let data = UserDefaults.standard.data(forKey: "userHealthProfile"),
           let profile = try? JSONDecoder().decode(UserHealthProfile.self, from: data) {
            _userProfile = profile
            MenuImageProcessor.shared.setUserProfile(profile)
        }
    }
} 

