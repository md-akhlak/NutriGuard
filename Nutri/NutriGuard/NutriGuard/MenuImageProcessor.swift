import Vision
import UIKit
import NaturalLanguage

class MenuImageProcessor {
    static let shared = MenuImageProcessor()
    
    // User's health profile
    private var userProfile: UserHealthProfile?
    
    private init() {}
    
    func setUserProfile(_ profile: UserHealthProfile) {
        self.userProfile = profile
    }
    
    func processMenuImage(_ image: UIImage, completion: @escaping ([MenuItem]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        
        // Create a new image-request handler
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Create a text recognition request
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  error == nil else {
                completion([])
                return
            }
            
            // Process the recognized text
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            // Parse menu items from the recognized text
            let menuItems = self?.parseMenuItems(from: recognizedStrings) ?? []
            completion(menuItems)
        }
        
        // Configure the text recognition request
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US", "es-ES", "fr-FR", "it-IT", "de-DE", "ja-JP", "zh-Hans", "zh-Hant", "ko-KR", "hi-IN", "ar-SA"]
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Failed to perform text recognition: \(error)")
            completion([])
        }
    }
    
    private func parseMenuItems(from textLines: [String]) -> [MenuItem] {
        var menuItems: [MenuItem] = []
        var currentItem: (name: String, price: String, description: String)?
        
        // First pass: Identify potential menu items and their prices
        var potentialItems: [(name: String, price: String, description: String)] = []
        
        for line in textLines {
            // Skip empty lines
            guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            
            // Try to extract price
            if let price = extractPrice(from: line) {
                // If we have a current item, save it
                if let item = currentItem {
                    potentialItems.append(item)
                }
                
                // Start new item
                let name = line.replacingOccurrences(of: price, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                currentItem = (name: name, price: price, description: "")
            } else if currentItem != nil {
                // Add to description if it looks like a description
                let line = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !line.isEmpty && !line.contains("$") && !line.contains("€") && !line.contains("£") {
                    currentItem?.description += line + " "
                } else {
                    // If the line contains a price or looks like a new item, save current and start new
                    if let item = currentItem {
                        potentialItems.append(item)
                    }
                    currentItem = (name: line, price: "", description: "")
                }
            } else {
                // Start new item without price
                currentItem = (name: line, price: "", description: "")
            }
        }
        
        // Add the last item if exists
        if let item = currentItem {
            potentialItems.append(item)
        }
        
        // Second pass: Clean up and create menu items
        for item in potentialItems {
            // Skip items that are too short to be valid menu items
            guard item.name.count > 2 else { continue }
            
            // Clean up the name and description
            let cleanName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanDescription = item.description.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Create menu item
            let menuItem = createMenuItem(
                name: cleanName,
                price: item.price,
                description: cleanDescription
            )
            
            menuItems.append(menuItem)
        }
        
        return menuItems
    }
    
    private func extractPrice(from text: String) -> String? {
        // Match various price formats
        let patterns = [
            #"\$\d+(\.\d{2})?"#,  // $10.99
            #"€\d+(\.\d{2})?"#,   // €10.99
            #"£\d+(\.\d{2})?"#,   // £10.99
            #"\d+(\.\d{2})?\s*(USD|EUR|GBP)"#,  // 10.99 USD
            #"\d+(\.\d{2})?\s*(dollars|euros|pounds)"#,  // 10.99 dollars
            #"\d+(\.\d{2})?\s*Rs"#,  // 10.99 Rs
            #"\d+(\.\d{2})?\s*INR"#   // 10.99 INR
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
                let range = Range(match.range, in: text)!
                return String(text[range])
            }
        }
        
        return nil
    }
    
    private func createMenuItem(name: String, price: String, description: String) -> MenuItem {
        // Use NLTagger to detect language and cuisine type
        let tagger = NLTagger(tagSchemes: [.language, .lexicalClass])
        tagger.string = name + " " + description
        
        // Detect language
        let language = tagger.dominantLanguage?.rawValue ?? "en"
        
        // Analyze text to determine cuisine type
        let cuisine = detectCuisine(from: name + " " + description)
        
        // Generate health impacts based on the dish description and user profile
        let healthImpacts = generateHealthImpacts(for: name, description: description)
        
        // Generate nutritional information
        let nutritionalInfo = generateNutritionalInfo(for: name, description: description)
        
        return MenuItem(
            name: name,
            cuisine: cuisine,
            price: price,
            rating: 0.0,
            healthScore: calculateHealthScore(for: name, description: description),
            allergens: detectAllergens(from: description),
            nutritionalInfo: nutritionalInfo,
            recommendation: generateRecommendation(for: name, description: description),
            healthImpacts: healthImpacts,
            dietaryBenefits: detectBenefits(from: description),
            dietaryConcerns: detectConcerns(from: description),
            alternativeOptions: generateAlternatives(for: name, cuisine: cuisine)
        )
    }
    
    private func calculateHealthScore(for name: String, description: String) -> Int {
        guard let profile = userProfile else { return 0 }
        
        var score = 100
        let text = (name + " " + description).lowercased()
        
        // Check for allergens
        for allergen in profile.foodAllergies {
            if text.contains(allergen.lowercased()) {
                score -= 30
            }
        }
        
        // Check for chronic conditions
        for condition in profile.chronicConditions {
            switch condition.lowercased() {
            case "diabetes":
                if text.contains("sugar") || text.contains("sweet") || text.contains("honey") {
                    score -= 20
                }
                if text.contains("whole grain") || text.contains("fiber") {
                    score += 10
                }
            case "hypertension":
                if text.contains("salt") || text.contains("sodium") {
                    score -= 20
                }
                if text.contains("low sodium") || text.contains("unsalted") {
                    score += 10
                }
            case "heart disease":
                if text.contains("fried") || text.contains("fatty") {
                    score -= 20
                }
                if text.contains("grilled") || text.contains("baked") {
                    score += 10
                }
            default:
                break
            }
        }
        
        // Check for diet type
        if let dietType = profile.dietType?.lowercased() {
            switch dietType {
            case "vegan":
                if text.contains("meat") || text.contains("dairy") || text.contains("egg") {
                    score -= 30
                }
            case "keto":
                if text.contains("carb") || text.contains("sugar") || text.contains("bread") {
                    score -= 20
                }
                if text.contains("fat") || text.contains("protein") {
                    score += 10
                }
            case "low-sodium":
                if text.contains("salt") || text.contains("sodium") {
                    score -= 25
                }
            default:
                break
            }
        }
        
        return max(0, min(100, score))
    }
    
    private func detectCuisine(from text: String) -> String {
        // Implement cuisine detection logic
        let cuisines = ["Italian", "Mexican", "Indian", "Chinese", "Japanese", "American"]
        let text = text.lowercased()
        
        for cuisine in cuisines {
            if text.contains(cuisine.lowercased()) {
                return cuisine
            }
        }
        
        // Default to American if no specific cuisine is detected
        return "American"
    }
    
    private func detectAllergens(from text: String) -> [String] {
        let commonAllergens = [
            "gluten", "dairy", "nuts", "peanuts", "shellfish",
            "fish", "eggs", "soy", "wheat", "sesame"
        ]
        
        return commonAllergens.filter { allergen in
            text.lowercased().contains(allergen)
        }
    }
    
    private func generateHealthImpacts(for name: String, description: String) -> [HealthImpact] {
        guard let profile = userProfile else { return [] }
        
        var impacts: [HealthImpact] = []
        let text = (name + " " + description).lowercased()
        
        // Check each chronic condition
        for condition in profile.chronicConditions {
            let (impact, recommendation, severity) = analyzeHealthImpact(
                for: condition,
                dishText: text
            )
            
            impacts.append(HealthImpact(
                condition: condition,
                impact: impact,
                recommendation: recommendation,
                severity: severity
            ))
        }
        
        return impacts
    }
    
    private func analyzeHealthImpact(for condition: String, dishText: String) -> (impact: String, recommendation: String, severity: ImpactSeverity) {
        switch condition.lowercased() {
        case "diabetes":
            if dishText.contains("sugar") || dishText.contains("sweet") {
                return (
                    "High sugar content may affect blood sugar levels",
                    "Consider asking for sugar-free alternatives or smaller portions",
                    .negative
                )
            } else if dishText.contains("whole grain") || dishText.contains("fiber") {
                return (
                    "Good source of fiber and complex carbohydrates",
                    "This is a good choice for diabetes management",
                    .positive
                )
            }
            return (
                "Moderate impact on blood sugar",
                "Monitor portion size and pair with protein",
                .neutral
            )
            
        case "hypertension":
            if dishText.contains("salt") || dishText.contains("sodium") {
                return (
                    "High sodium content may affect blood pressure",
                    "Request low-sodium preparation or smaller portions",
                    .negative
                )
            } else if dishText.contains("low sodium") || dishText.contains("unsalted") {
                return (
                    "Low sodium content is good for blood pressure",
                    "This is a good choice for hypertension management",
                    .positive
                )
            }
            return (
                "Moderate sodium content",
                "Monitor portion size and avoid adding extra salt",
                .neutral
            )
            
        case "heart disease":
            if dishText.contains("fried") || dishText.contains("fatty") {
                return (
                    "High in saturated fats may affect heart health",
                    "Consider grilled or baked alternatives",
                    .negative
                )
            } else if dishText.contains("grilled") || dishText.contains("baked") {
                return (
                    "Low in saturated fats, good for heart health",
                    "This is a good choice for heart health",
                    .positive
                )
            }
            return (
                "Moderate impact on heart health",
                "Monitor portion size and fat content",
                .neutral
            )
            
        default:
            return (
                "General health impact",
                "Consider your overall dietary needs",
                .neutral
            )
        }
    }
    
    private func generateNutritionalInfo(for name: String, description: String) -> [String: String] {
        // This would be replaced with actual nutritional analysis
        return [
            "Calories": "Analyzing...",
            "Protein": "Analyzing...",
            "Carbs": "Analyzing...",
            "Fat": "Analyzing..."
        ]
    }
    
    private func generateRecommendation(for name: String, description: String) -> String {
        guard let profile = userProfile else {
            return "Please complete your health profile for personalized recommendations"
        }
        
        let healthScore = calculateHealthScore(for: name, description: description)
        
        if healthScore >= 80 {
            return "Excellent choice! This dish aligns well with your health profile."
        } else if healthScore >= 60 {
            return "Good option, but consider portion size and preparation method."
        } else {
            return "This dish may not be the best choice for your health profile. Consider alternatives."
        }
    }
    
    private func detectBenefits(from text: String) -> [String] {
        guard let profile = userProfile else { return [] }
        
        var benefits: [String] = []
        let text = text.lowercased()
        
        // Check for diet-specific benefits
        if let dietType = profile.dietType?.lowercased() {
            switch dietType {
            case "vegan":
                if text.contains("vegetable") || text.contains("plant") {
                    benefits.append("Rich in plant-based nutrients")
                }
            case "keto":
                if text.contains("protein") || text.contains("fat") {
                    benefits.append("Good source of protein and healthy fats")
                }
            case "low-sodium":
                if text.contains("low sodium") || text.contains("unsalted") {
                    benefits.append("Low in sodium")
                }
            default:
                break
            }
        }
        
        // Add general benefits
        if text.contains("grilled") || text.contains("baked") {
            benefits.append("Low in unhealthy fats")
        }
        if text.contains("vegetable") || text.contains("salad") {
            benefits.append("Rich in vitamins and minerals")
        }
        if text.contains("whole grain") || text.contains("fiber") {
            benefits.append("Good source of fiber")
        }
        
        return benefits
    }
    
    private func detectConcerns(from text: String) -> [String] {
        guard let profile = userProfile else { return [] }
        
        var concerns: [String] = []
        let text = text.lowercased()
        
        // Check for allergens
        for allergen in profile.foodAllergies {
            if text.contains(allergen.lowercased()) {
                concerns.append("Contains \(allergen)")
            }
        }
        
        // Check for chronic conditions
        for condition in profile.chronicConditions {
            switch condition.lowercased() {
            case "diabetes":
                if text.contains("sugar") || text.contains("sweet") {
                    concerns.append("High in sugar")
                }
            case "hypertension":
                if text.contains("salt") || text.contains("sodium") {
                    concerns.append("High in sodium")
                }
            case "heart disease":
                if text.contains("fried") || text.contains("fatty") {
                    concerns.append("High in saturated fats")
                }
            default:
                break
            }
        }
        
        return concerns
    }
    
    private func generateAlternatives(for name: String, cuisine: String) -> [String] {
        guard let profile = userProfile else { return [] }
        
        var alternatives: [String] = []
        let text = name.lowercased()
        
        // Generate alternatives based on cuisine and health profile
        switch cuisine.lowercased() {
        case "italian":
            if text.contains("pasta") {
                alternatives.append("Zucchini Noodles")
                alternatives.append("Whole Wheat Pasta")
            }
            if text.contains("pizza") {
                alternatives.append("Cauliflower Crust Pizza")
            }
        case "mexican":
            if text.contains("taco") {
                alternatives.append("Lettuce Wrap Tacos")
            }
            if text.contains("burrito") {
                alternatives.append("Bowl Style (No Tortilla)")
            }
        case "indian":
            if text.contains("curry") {
                alternatives.append("Tofu Curry")
                alternatives.append("Vegetable Curry")
            }
        default:
            break
        }
        
        // Add general alternatives based on health profile
        if profile.chronicConditions.contains("Diabetes") {
            alternatives.append("Grilled Protein with Vegetables")
        }
        if profile.chronicConditions.contains("Hypertension") {
            alternatives.append("Low-Sodium Options")
        }
        if profile.chronicConditions.contains("Heart Disease") {
            alternatives.append("Grilled or Baked Options")
        }
        
        return alternatives
    }
}

// User Health Profile Structure
struct UserHealthProfile {
    let chronicConditions: [String]
    let foodAllergies: [String]
    let medications: [String]
    let dietType: String?
    let permanentDislikes: [String]
    let activityLevel: String
    let longTermGoals: [String]
} 