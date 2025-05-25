import Foundation

class GeminiService {
    static let shared = GeminiService()
    private let apiKey = "AIzaSyD5r7Vkkdqkq7LbX4oVIrlCM_oRdVLzFRc"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    
    // Rate limiting properties
    private let maxRetries = 3
    private let initialRetryDelay: TimeInterval = 2.0 // Initial delay in seconds
    private var lastRequestTime: Date?
    private let minTimeBetweenRequests: TimeInterval = 1.0 // 1 second between requests
    
    private init() {
        print("🚀 GeminiService initialized")
    }
    
    private func waitForNextRequestWindow() async throws {
        guard let lastRequest = lastRequestTime else {
            lastRequestTime = Date()
            return
        }
        
        let timeSinceLastRequest = Date().timeIntervalSince(lastRequest)
        if timeSinceLastRequest < minTimeBetweenRequests {
            let waitTime = minTimeBetweenRequests - timeSinceLastRequest
            print("⏳ Waiting \(Int(waitTime)) seconds before next request...")
            try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        lastRequestTime = Date()
    }
    
    private func makeRequest(_ request: URLRequest, retryCount: Int = 0) async throws -> (Data, URLResponse) {
        do {
            try await waitForNextRequestWindow()
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Print response headers for debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Response Status Code: \(httpResponse.statusCode)")
                print("📡 Response Headers:")
                for (key, value) in httpResponse.allHeaderFields {
                    print("   \(key): \(value)")
                }
            }
            
            return (data, response)
        } catch {
            print("❌ Error in makeRequest: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("🌐 Network error code: \(urlError.code)")
                if retryCount < maxRetries {
                    let delay = initialRetryDelay * pow(2.0, Double(retryCount))
                    print("🔄 Retrying in \(Int(delay)) seconds... (Attempt \(retryCount + 1)/\(maxRetries))")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await makeRequest(request, retryCount: retryCount + 1)
                }
            }
            throw error
        }
    }
    
    func analyzeMenuItem(_ item: MenuItem, userProfile: UserHealthProfile) async throws -> (HealthAnalysis, [String: String]) {
        print("📝 Preparing Gemini API request for: \(item.name)")
        
        if item.name.count < 3 || item.name.lowercased() == "cafe" {
            print("⚠️ Item name too short or generic, using default analysis")
            return createDefaultAnalysis(for: item)
        }

        let prompt = """
        Return ONLY a JSON response analyzing this menu item. No explanations or questions.

        ITEM DETAILS:
        Name: \(item.name)
        Description: \(item.description)
        Cuisine: \(item.cuisine)

        USER PROFILE:
        Health Conditions: \(userProfile.chronicConditions.joined(separator: ", "))
        Allergies: \(userProfile.foodAllergies.joined(separator: ", "))
        Diet Type: \(userProfile.dietType ?? "None")

        TASK:
        1. Analyze the dish based on its name, description, and cuisine.
        2. Provide accurate nutritional estimates based on standard serving size.
        3. Consider cooking method, ingredients, and portion size.

        REQUIRED FORMAT:
        {
            "isHealthy": false,
            "reason": "one sentence about safety for this user",
            "healthImpacts": [
                "key impact for user condition",
                "key risk if relevant"
            ],
            "recommendations": [
                "main modification if needed",
                "alternative suggestion"
            ],
            "nutritionalInfo": {
                "Calories": "estimated calories based on ingredients and portion",
                "Protein": "estimated protein content in grams",
                "Carbs": "estimated carbohydrate content in grams",
                "Fat": "estimated fat content in grams",
                "Fiber": "estimated fiber content in grams",
                "Sugar": "estimated sugar content in grams",
                "Sodium": "estimated sodium content in mg"
            }
        }
        """
        
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
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = jsonData
        
        print("🌐 Sending request to Gemini API")
        let (responseData, urlResponse) = try await makeRequest(request)
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }
        
        // Print response data for debugging
        print("📥 Response Status Code: \(httpResponse.statusCode)")
        if let responseString = String(data: responseData, encoding: .utf8) {
            print("📥 Response Data: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ API Error: Status code \(httpResponse.statusCode)")
            if let errorJson = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
                print("Error details: \(errorJson)")
            }
            return createDefaultAnalysis(for: item)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            print("❌ Invalid response format from API")
            print("Response structure not as expected")
            return createDefaultAnalysis(for: item)
        }

        print("📝 Raw text from API: \(text)")

        // Extract JSON from the text, handling both code block and direct JSON cases
        let cleanedText = text.replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        print("📝 Cleaned text: \(cleanedText)")

        guard let data = cleanedText.data(using: .utf8) else {
            print("❌ Failed to convert text to data")
            return createDefaultAnalysis(for: item)
        }

        do {
            guard let analysisJson = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ Failed to parse JSON from cleaned text")
                return createDefaultAnalysis(for: item)
            }

            guard let isHealthy = analysisJson["isHealthy"] as? Bool,
                  let reason = analysisJson["reason"] as? String,
                  let healthImpacts = analysisJson["healthImpacts"] as? [String],
                  let recommendations = analysisJson["recommendations"] as? [String],
                  let nutritionalInfo = analysisJson["nutritionalInfo"] as? [String: String] else {
                print("❌ Missing required fields in parsed JSON")
                print("Available keys: \(analysisJson.keys.joined(separator: ", "))")
                return createDefaultAnalysis(for: item)
            }

            let healthAnalysis = HealthAnalysis(
                isHealthy: isHealthy,
                reason: reason,
                healthImpacts: healthImpacts,
                recommendations: recommendations
            )

            return (healthAnalysis, nutritionalInfo)
        } catch {
            print("❌ JSON parsing error: \(error.localizedDescription)")
            return createDefaultAnalysis(for: item)
        }
    }
    
    private func createDefaultAnalysis(for item: MenuItem) -> (HealthAnalysis, [String: String]) {
        print("⚠️ Creating default analysis for item: \(item.name)")
        let healthAnalysis = HealthAnalysis(
            isHealthy: true,
            reason: "Unable to perform detailed analysis at the moment. Please try again in a few minutes.",
            healthImpacts: ["No specific health impacts could be determined at this time."],
            recommendations: [
                "Consider checking with staff about ingredients and preparation methods.",
                "Try analyzing this item again in a few minutes."
            ]
        )
        
        let nutritionalInfo: [String: String] = [
            "Calories": "Analysis needed",
            "Protein": "Analysis needed",
            "Carbs": "Analysis needed",
            "Fat": "Analysis needed",
            "Fiber": "Analysis needed",
            "Sugar": "Analysis needed",
            "Sodium": "Analysis needed"
        ]
        
        return (healthAnalysis, nutritionalInfo)
    }
} 