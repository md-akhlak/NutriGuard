import Vision
import UIKit
import NaturalLanguage

class MenuImageProcessor {
    static let shared = MenuImageProcessor()
    
    // User's health profile
    private(set) var userProfile: UserHealthProfile?
    
    private init() {}
    
    func setUserProfile(_ profile: UserHealthProfile) {
        self.userProfile = profile
    }
    
    func getUserProfile() -> UserHealthProfile? {
        return userProfile
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
            
            // Sort observations by vertical position (top to bottom)
            let sortedObservations = observations.sorted { obs1, obs2 in
                obs1.boundingBox.origin.y > obs2.boundingBox.origin.y
            }
            
            // Process the recognized text with position information
            let recognizedStrings = sortedObservations.compactMap { observation -> (String, CGRect)? in
                guard let text = observation.topCandidates(1).first?.string else { return nil }
                return (text, observation.boundingBox)
            }
            
            // Clean and filter the recognized text
            let cleanedText = self?.cleanRecognizedText(recognizedStrings) ?? []
            
            // Parse menu items from the cleaned text
            let menuItems = self?.parseMenuItems(from: cleanedText) ?? []
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
    
    private func cleanRecognizedText(_ textLines: [(String, CGRect)]) -> [(String, CGRect)] {
        return textLines.compactMap { (text, position) -> (String, CGRect)? in
            // Remove unwanted characters and clean the text
            var cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip if the text is too short (likely noise)
            if cleanedText.count < 2 {
                return nil
            }
            
            // Remove common menu noise
            let noisePatterns = [
                #"\.{2,}"#,  // Multiple dots
                #"^[•\-\*]+$"#,  // Lines of bullets
                #"^[0-9]+$"#,  // Just numbers
                #"^[A-Za-z]\.$"#,  // Single letter with dot
                #"^[•\-\*]\s*$"#,  // Single bullet
                #"^\s*[•\-\*]\s*$"#,  // Bullet with spaces
                #"^[0-9]+\s*[A-Za-z]$"#,  // Number followed by letter
                #"^[A-Za-z]\s*[0-9]+$"#,  // Letter followed by number
                #"^[0-9]+\s*[•\-\*]$"#,  // Number followed by bullet
                #"^[•\-\*]\s*[0-9]+$"#  // Bullet followed by number
            ]
            
            for pattern in noisePatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                    cleanedText = regex.stringByReplacingMatches(
                        in: cleanedText,
                        options: [],
                        range: NSRange(cleanedText.startIndex..., in: cleanedText),
                        withTemplate: ""
                    )
                }
            }
            
            // Clean up any remaining unwanted characters
            cleanedText = cleanedText.replacingOccurrences(of: "•", with: "")
                .replacingOccurrences(of: "·", with: "")
                .replacingOccurrences(of: "…", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip if the text is empty after cleaning
            if cleanedText.isEmpty {
                return nil
            }
            
            // Skip if the text is just numbers or starts with numbers
            if cleanedText.range(of: #"^[0-9]+"#, options: .regularExpression) != nil {
                return nil
            }
            
            return (cleanedText, position)
        }
    }
    
    private func parseMenuItems(from textLines: [(String, CGRect)]) -> [MenuItem] {
        var menuItems: [MenuItem] = []
        var currentItem: (name: String, price: String, description: String, position: CGRect)?
        
        for (line, position) in textLines {
            // Skip empty lines
            guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            
            // Try to extract price
            if let price = extractPrice(from: line) {
                if let item = currentItem {
                    // Create menu item with the collected information
                    let menuItem = createMenuItem(
                        name: item.name,
                        price: price,
                        description: item.description
                    )
                    menuItems.append(menuItem)
                }
                
                // Clean the name by removing the price and any leading/trailing dots
                let name = line.replacingOccurrences(of: price, with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: #"^\.+|\.+$"#, with: "", options: .regularExpression)
                
                // Skip if the name is just numbers or starts with numbers
                if name.range(of: #"^[0-9]+"#, options: .regularExpression) != nil {
                    continue
                }
                
                // Start new item
                currentItem = (
                    name: name,
                    price: price,
                    description: "",
                    position: position
                )
            } else if let current = currentItem {
                // Check if this line is part of the current item or a new item
                if isPartOfCurrentItem(currentPosition: position, previousPosition: current.position) {
                    // Clean the description line
                    let cleanedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: #"^\.+|\.+$"#, with: "", options: .regularExpression)
                    
                    // Skip if the line is just numbers
                    if cleanedLine.range(of: #"^[0-9]+$"#, options: .regularExpression) != nil {
                        continue
                    }
                    
                    // Add to description if not empty
                    if !cleanedLine.isEmpty {
                        currentItem?.description += cleanedLine + " "
                    }
                } else {
                    // Create menu item with the collected information
                    let menuItem = createMenuItem(
                        name: current.name,
                        price: current.price,
                        description: current.description
                    )
                    menuItems.append(menuItem)
                    
                    // Start new item
                    currentItem = (name: line, price: "", description: "", position: position)
                }
            } else {
                // Skip if the line is just numbers
                if line.range(of: #"^[0-9]+$"#, options: .regularExpression) != nil {
                    continue
                }
                
                // Start new item without price
                currentItem = (name: line, price: "", description: "", position: position)
            }
        }
        
        // Add the last item if exists
        if let item = currentItem {
            let menuItem = createMenuItem(
                name: item.name,
                price: item.price,
                description: item.description
            )
            menuItems.append(menuItem)
        }
        
        // Filter out any items that are likely not food items
        return menuItems.filter { item in
            !isLikelyNotFoodItem(item.name)
        }
    }
    
    private func isLikelyNotFoodItem(_ text: String) -> Bool {
        // Patterns that indicate the text is likely not a food item
        let nonFoodPatterns = [
            #"^[0-9]+$"#,  // Just numbers
            #"^[A-Za-z]\.$"#,  // Single letter with dot
            #"^[•\-\*]+$"#,  // Just bullets
            #"^[A-Za-z]$"#,  // Single letter
            #"^[0-9]+\s*[A-Za-z]$"#,  // Number followed by single letter
            #"^[A-Za-z]\s*[0-9]+$"#,  // Single letter followed by number
            #"^[•\-\*]\s*[A-Za-z0-9]$"#,  // Bullet followed by letter/number
            #"^[A-Za-z0-9]\s*[•\-\*]$"#,  // Letter/number followed by bullet
            #"^[0-9]+\s*[•\-\*]$"#,  // Number followed by bullet
            #"^[•\-\*]\s*[0-9]+$"#,  // Bullet followed by number
            #"^[0-9]+[A-Za-z]$"#,  // Number followed by letter
            #"^[A-Za-z][0-9]+$"#  // Letter followed by number
        ]
        
        for pattern in nonFoodPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) != nil {
                return true
            }
        }
        
        // Check if the text is too short to be a food item
        if text.count < 3 {
            return true
        }
        
        // Check if the text starts with numbers
        if text.range(of: #"^[0-9]+"#, options: .regularExpression) != nil {
            return true
        }
        
        return false
    }
    
    private func isPartOfCurrentItem(currentPosition: CGRect, previousPosition: CGRect) -> Bool {
        // Check if the current line is close to the previous line vertically
        let verticalThreshold: CGFloat = 0.05 // Adjust this value based on your needs
        let verticalDistance = abs(currentPosition.origin.y - previousPosition.origin.y)
        
        // Check if the current line is aligned with the previous line horizontally
        let horizontalThreshold: CGFloat = 0.1 // Adjust this value based on your needs
        let horizontalDistance = abs(currentPosition.origin.x - previousPosition.origin.x)
        
        return verticalDistance < verticalThreshold && horizontalDistance < horizontalThreshold
    }
    
    private func extractPrice(from text: String) -> String? {
        // Match various price formats
        let patterns = [
            #"\$\d+(\.\d{2})?"#,  // $10.99
            #"€\d+(\.\d{2})?"#,   // €10.99
            #"£\d+(\.\d{2})?"#,   // £10.99
            #"\d+(\.\d{2})?\s*(USD|EUR|GBP)"#,  // 10.99 USD
            #"\d+(\.\d{2})?\s*(dollars|euros|pounds)"#,  // 10.99 dollars
            #"\d+(\.\d{2})?"#  // 10.99
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
            description: description,
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
        
        // More significant penalties for health concerns
        for allergen in profile.foodAllergies {
            if text.contains(allergen.lowercased()) {
                score -= 50  // Increased penalty for allergens
            }
        }
        
        // Check for chronic conditions with stricter penalties
        for condition in profile.chronicConditions {
            switch condition.lowercased() {
            case "diabetes":
                if text.contains("sugar") || text.contains("sweet") || text.contains("honey") {
                    score -= 40  // Increased penalty
                }
                if text.contains("whole grain") || text.contains("fiber") {
                    score += 10
                }
            case "hypertension":
                if text.contains("salt") || text.contains("sodium") || text.contains("soy sauce") {
                    score -= 40  // Increased penalty
                }
                if text.contains("low sodium") || text.contains("unsalted") {
                    score += 10
                }
            case "heart disease":
                if text.contains("fried") || text.contains("fatty") || text.contains("cream") {
                    score -= 40  // Increased penalty
                }
                if text.contains("grilled") || text.contains("baked") || text.contains("steamed") {
                    score += 10
                }
            default:
                break
            }
        }
        
        // Additional penalties for unhealthy cooking methods
        if text.contains("fried") || text.contains("deep fried") {
            score -= 30
        }
        if text.contains("cream sauce") || text.contains("butter sauce") {
            score -= 20
        }
        if text.contains("extra cheese") || text.contains("creamy") {
            score -= 20
        }
        
        // Bonuses for healthy ingredients
        if text.contains("vegetable") || text.contains("salad") {
            score += 15
        }
        if text.contains("lean") || text.contains("grilled") {
            score += 10
        }
        if text.contains("whole grain") || text.contains("brown rice") {
            score += 10
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
        // Use Gemini API to get nutritional info
        guard let profile = userProfile else {
            return [
                "Calories": "N/A",
                "Protein": "N/A",
                "Carbs": "N/A",
                "Fat": "N/A"
            ]
        }
        
        let menuItem = MenuItem(
            name: name,
            cuisine: detectCuisine(from: description),
            price: "",
            description: description,
            rating: 0.0,
            healthScore: 0,
            allergens: [],
            nutritionalInfo: [:],
            recommendation: "",
            healthImpacts: [],
            dietaryBenefits: [],
            dietaryConcerns: [],
            alternativeOptions: []
        )
        
        // Return placeholder values while analysis is in progress
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
        let text = (name + " " + description).lowercased()

        // Check for unhealthy indicators
        let hasHighCalories = text.contains("fried") || text.contains("deep fried") || text.contains("crispy")
        let hasHighSodium = text.contains("salt") || text.contains("soy sauce") || text.contains("sauce")
        let hasHighFat = text.contains("cream") || text.contains("butter") || text.contains("cheese")
        let hasHighSugar = text.contains("sweet") || text.contains("sugar") || text.contains("syrup")

        // More strict health scoring
        if healthScore >= 80 && !hasHighCalories && !hasHighSodium && !hasHighFat && !hasHighSugar {
            return ""
        } else if healthScore >= 60 {
            return ""
        } else {
            return ""
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

