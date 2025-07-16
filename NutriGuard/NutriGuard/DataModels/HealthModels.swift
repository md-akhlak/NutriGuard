import Foundation
import SwiftUI

struct UserHealthProfile: Codable {
    let chronicConditions: [String]
    let foodAllergies: [String]
    let medications: [String]
    let dietType: String?
    let permanentDislikes: [String]
    let activityLevel: String
    let longTermGoals: [String]
}

struct HealthImpact: Identifiable {
    let id = UUID()
    let condition: String
    let impact: String
    let recommendation: String
    let severity: ImpactSeverity
}

enum ImpactSeverity: String {
    case positive = "Positive"
    case neutral = "Neutral"
    case negative = "Negative"
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .neutral: return .orange
        case .negative: return .red
        }
    }
}

struct HealthAnalysis: Codable {
    let isHealthy: Bool
    let reason: String
    let healthImpacts: [String]
    let recommendations: [String]
} 
