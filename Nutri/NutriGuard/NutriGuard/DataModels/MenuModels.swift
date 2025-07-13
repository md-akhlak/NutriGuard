import Foundation

struct MenuItem: Identifiable {
    let id = UUID()
    var name: String
    var cuisine: String
    var price: String
    var description: String
    var rating: Double
    var healthScore: Int
    var allergens: [String]
    var nutritionalInfo: [String: String]
    var recommendation: String
    var healthImpacts: [HealthImpact]
    var dietaryBenefits: [String]
    var dietaryConcerns: [String]
    var alternativeOptions: [String]
}

// Response models for Gemini API
struct GeminiResponse: Codable {
    let candidates: [Candidate]
    
    enum CodingKeys: String, CodingKey {
        case candidates
    }
}

struct Candidate: Codable {
    let content: Content
    
    enum CodingKeys: String, CodingKey {
        case content
    }
}

struct Content: Codable {
    let parts: [Part]
    
    enum CodingKeys: String, CodingKey {
        case parts
    }
}

struct Part: Codable {
    let text: String
    
    enum CodingKeys: String, CodingKey {
        case text
    }
} 