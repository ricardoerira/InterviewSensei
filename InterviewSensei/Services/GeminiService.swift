import Foundation

class GeminiService {
    private let apiKey = "AIzaSyARk8ONzJROzRw1i1l2HP8GYjwMI88_9iI"
    private let baseURL = "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent"

  //
    func generateResponse(for prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(GeminiResponse.self, from: data)
        
        return result.candidates.first?.content.parts.first?.text ?? "No response generated"
    }
}

// MARK: - Response Models
struct GeminiResponse: Codable {
    let candidates: [Candidate]
}

struct Candidate: Codable {
    let content: GeminiContent
}

struct GeminiContent: Codable {
    let parts: [Part]
}

struct Part: Codable {
    let text: String
} 
