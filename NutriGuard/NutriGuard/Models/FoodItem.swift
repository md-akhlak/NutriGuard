import Foundation

struct NutritionalInfo {
    var calories: Int
    var carbohydrates: Double
    var proteins: Double
    var fats: Double
    var sodium: Double
    var sugar: Double
    var allergens: [String]
}

struct FoodItem: Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var ingredients: [String]
    var nutritionalInfo: NutritionalInfo
    
    func isSafeFor(profile: UserProfile) -> Bool {
        let restrictions = profile.getAllRestrictions()
        
        // Check ingredients against restrictions
        for ingredient in ingredients {
            if restrictions.contains(where: { ingredient.lowercased().contains($0.lowercased()) }) {
                return false
            }
        }
        
        // Check allergens
        for allergen in nutritionalInfo.allergens {
            if restrictions.contains(where: { allergen.lowercased().contains($0.lowercased()) }) {
                return false
            }
        }
        
        // Additional checks for specific conditions
        if profile.medicalConditions.contains(.diabetes) {
            if nutritionalInfo.sugar > 10 { // More than 10g sugar per serving
                return false
            }
        }
        
        if profile.medicalConditions.contains(.hypertension) {
            if nutritionalInfo.sodium > 400 { // More than 400mg sodium per serving
                return false
            }
        }
        
        return true
    }
    
    func getSafetyWarnings(profile: UserProfile) -> [String] {
        var warnings: [String] = []
        let restrictions = profile.getAllRestrictions()
        
        // Check ingredients
        for ingredient in ingredients {
            if let restriction = restrictions.first(where: { ingredient.lowercased().contains($0.lowercased()) }) {
                warnings.append("Contains \(ingredient) (restricted due to \(restriction))")
            }
        }
        
        // Check specific conditions
        if profile.medicalConditions.contains(.diabetes) && nutritionalInfo.sugar > 10 {
            warnings.append("High sugar content (\(nutritionalInfo.sugar)g)")
        }
        
        if profile.medicalConditions.contains(.hypertension) && nutritionalInfo.sodium > 400 {
            warnings.append("High sodium content (\(nutritionalInfo.sodium)mg)")
        }
        
        return warnings
    }
} 