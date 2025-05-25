import Foundation

class GeminiService {
    static let shared = GeminiService()
    private let apiKey = "AIzaSyDhuGZKQvsR-_ciumgFOMc31avPmNibrp0" // Replace with your actual API key
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
    
    private init() {
        print("🚀 GeminiService initialized")
    }
    
    func analyzeMenuItem(_ item: MenuItem, userProfile: UserHealthProfile) async throws -> HealthAnalysis {
        print("📝 Preparing Gemini API request for: \(item.name)")
        
        let prompt = """
        Analyze this menu item for a user with the following health profile:
        
        Menu Item: \(item.name)
        Description: \(item.description)
        Cuisine: \(item.cuisine)
        
        User Health Profile:
        - Chronic Conditions: \(userProfile.chronicConditions.joined(separator: ", "))
        - Food Allergies: \(userProfile.foodAllergies.joined(separator: ", "))
        - Diet Type: \(userProfile.dietType ?? "None")
        - Activity Level: \(userProfile.activityLevel)
        
        Please provide:
        1. Is this item healthy or unhealthy for this specific user?
        2. Detailed reasons why (considering their health conditions and restrictions)
        3. Specific health impacts
        4. Recommendations for alternatives or modifications
        
        Format the response as JSON with the following structure:
        {
            "isHealthy": boolean,
            "reason": "detailed explanation",
            "healthImpacts": ["impact1", "impact2"],
            "recommendations": ["rec1", "rec2"]
        }
        """
        
        print("📋 Generated prompt for Gemini API")
        
        let url = URL(string: "\(baseURL)?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        print("🌐 Sending request to Gemini API...")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, httpResponse) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = httpResponse as? HTTPURLResponse {
                print("📡 Received response from Gemini API - Status code: \(httpResponse.statusCode)")
            }
            
            print("📦 Received data from Gemini API")
            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            
            // Parse the response text as JSON
            if let responseText = geminiResponse.candidates.first?.content.parts.first?.text,
               let jsonData = responseText.data(using: String.Encoding.utf8) {
                print("🔍 Parsing Gemini API response")
                print("Raw response text: \(responseText)")
                
                if let analysis = try? JSONDecoder().decode(HealthAnalysis.self, from: jsonData) {
                    print("✅ Successfully parsed analysis from Gemini API")
                    return analysis
                } else {
                    print("❌ Failed to parse analysis from Gemini API response")
                    print("Raw response: \(responseText)")
                }
            }
            
            throw NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        } catch {
            print("❌ Error in Gemini API call: \(error.localizedDescription)")
            throw error
        }
    }
}

// Response models
struct GeminiResponse: Codable {
    let candidates: [Candidate]
}

struct Candidate: Codable {
    let content: Content
}

struct Content: Codable {
    let parts: [Part]
}

struct Part: Codable {
    let text: String
}

struct HealthAnalysis: Codable {
    let isHealthy: Bool
    let reason: String
    let healthImpacts: [String]
    let recommendations: [String]
} 
