import Foundation

enum MedicalCondition: String, CaseIterable, Identifiable {
    case diabetes
    case hypertension
    case celiacDisease
    case lactoseIntolerance
    case nutAllergy
    case shellfishAllergy
    
    var id: String { self.rawValue }
    
    var dietaryRestrictions: [String] {
        switch self {
        case .diabetes:
            return ["sugar", "high-carb foods"]
        case .hypertension:
            return ["high-sodium foods"]
        case .celiacDisease:
            return ["gluten", "wheat"]
        case .lactoseIntolerance:
            return ["dairy", "milk", "cheese"]
        case .nutAllergy:
            return ["nuts", "peanuts", "tree nuts"]
        case .shellfishAllergy:
            return ["shellfish", "seafood"]
        }
    }
}

struct MealEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let foodItems: [String]
    let reactions: [String]
    let notes: String
    
    init(id: UUID = UUID(), date: Date = Date(), foodItems: [String], reactions: [String] = [], notes: String = "") {
        self.id = id
        self.date = date
        self.foodItems = foodItems
        self.reactions = reactions
        self.notes = notes
    }
}

enum FoodSafetyLevel: String {
    case safe = "green"
    case caution = "yellow"
    case unsafe = "red"
}

class UserProfile: ObservableObject {
    @Published var name: String
    @Published var medicalConditions: Set<MedicalCondition>
    @Published var additionalRestrictions: [String]
    @Published var mealLog: [MealEntry]
    
    init(name: String = "", 
         medicalConditions: Set<MedicalCondition> = [],
         additionalRestrictions: [String] = [],
         mealLog: [MealEntry] = []) {
        self.name = name
        self.medicalConditions = medicalConditions
        self.additionalRestrictions = additionalRestrictions
        self.mealLog = mealLog
    }
    
    func getAllRestrictions() -> [String] {
        var restrictions: [String] = []
        for condition in medicalConditions {
            restrictions.append(contentsOf: condition.dietaryRestrictions)
        }
        restrictions.append(contentsOf: additionalRestrictions)
        return restrictions
    }
    
    func checkFoodSafety(ingredients: [String]) -> FoodSafetyLevel {
        let restrictions = getAllRestrictions()
        let lowercaseIngredients = ingredients.map { $0.lowercased() }
        let lowercaseRestrictions = restrictions.map { $0.lowercased() }
        
        for ingredient in lowercaseIngredients {
            if lowercaseRestrictions.contains(where: { ingredient.contains($0) }) {
                return .unsafe
            }
        }
        
        // Check for potential cross-contamination or similar ingredients
        for ingredient in lowercaseIngredients {
            if lowercaseRestrictions.contains(where: { 
                ingredient.contains($0) || $0.contains(ingredient)
            }) {
                return .caution
            }
        }
        
        return .safe
    }
    
    func addMealEntry(foodItems: [String], reactions: [String] = [], notes: String = "") {
        let newEntry = MealEntry(foodItems: foodItems, reactions: reactions, notes: notes)
        mealLog.append(newEntry)
    }
} 