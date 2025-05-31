import Foundation
import CoreData


class CVProcessingService {
    private let geminiService: GeminiService
    private let context: NSManagedObjectContext
    
    init(geminiService: GeminiService, context: NSManagedObjectContext) {
        self.geminiService = geminiService
        self.context = context
    }
    
    func processCV(_ cvText: String) async throws -> CVInfo {
        // Create prompt for Gemini to extract CV information
        let prompt = """
        Extract the following information from this CV and format it as a valid JSON object. Make sure all dates are in YYYY-MM-DD format.
        
        Required fields:
        - name (string)
        - email (string)
        - phone (string)
        - summary (string)
        - experience (array of objects with: company, position, startDate, endDate, jobDescription)
        - education (array of objects with: institution, degree, field, startDate, endDate)
        - skills (array of strings)
        
        Example format:
        {
            "name": "John Doe",
            "email": "john@example.com",
            "phone": "+1234567890",
            "summary": "Experienced software engineer...",
            "experience": [
                {
                    "company": "Tech Corp",
                    "position": "Senior Developer",
                    "startDate": "2020-01-01",
                    "endDate": "2023-12-31",
                    "jobDescription": "Led development of..."
                }
            ],
            "education": [
                {
                    "institution": "University",
                    "degree": "Bachelor of Science",
                    "field": "Computer Science",
                    "startDate": "2016-09-01",
                    "endDate": "2020-06-30"
                }
            ],
            "skills": ["Swift", "iOS Development", "CoreData"]
        }
        
        IMPORTANT: Return ONLY the JSON object, with no additional text, markdown formatting, or code blocks. Do not include any explanations or notes.
        
        CV Text:
        \(cvText)
        """
        
        // Get response from Gemini
        let response = try await geminiService.generateResponse(for: prompt)
        
        // Print the raw response for debugging
        print("Raw AI Response: \(response)")
        
        // Extract JSON content from the response
        let jsonContent: String
        if let startIndex = response.range(of: "{")?.lowerBound,
           let endIndex = response.range(of: "}", options: .backwards)?.upperBound {
            jsonContent = String(response[startIndex..<endIndex])
        } else {
            print("Failed to find JSON content in response")
            throw CVProcessingError.invalidResponse
        }
        
        print("Extracted JSON content: \(jsonContent)")
        
        // Clean and validate the JSON content
        let cleanedJson = cleanJsonString(jsonContent)
        print("Cleaned JSON: \(cleanedJson)")
        
        // Validate JSON structure
        guard let jsonData = cleanedJson.data(using: .utf8) else {
            print("Failed to convert cleaned JSON to data")
            throw CVProcessingError.invalidResponse
        }
        
        do {
            // Try to parse as dictionary first
            if let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                print("Valid JSON structure: \(jsonDict)")
            } else {
                print("JSON is not a dictionary")
                throw CVProcessingError.invalidResponse
            }
        } catch {
            print("JSON validation error: \(error)")
            throw CVProcessingError.invalidResponse
        }
        
        let cvData: CVData
        do {
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            cvData = try decoder.decode(CVData.self, from: jsonData)
        } catch {
            print("JSON Decoding Error: \(error)")
            throw CVProcessingError.jsonParsingError(error.localizedDescription)
        }
        
        // Create and save CVInfo in CoreData
        do {
            return try await context.perform {
                let cvInfo = CVInfo(context: self.context)
                cvInfo.id = UUID()
                cvInfo.name = cvData.name
                cvInfo.email = cvData.email
                cvInfo.phone = cvData.phone
                cvInfo.summary = cvData.summary
                cvInfo.skills = cvData.skills
                cvInfo.createdAt = Date()
                cvInfo.updatedAt = Date()
                
                // Create Experience entities
                for exp in cvData.experience {
                    let experience = Experience(context: self.context)
                    experience.id = UUID()
                    experience.company = exp.company
                    experience.position = exp.position
                    experience.startDate = exp.startDate
                    experience.endDate = exp.endDate
                    experience.jobDescription = exp.jobDescription
                    experience.cvInfo = cvInfo
                }
                
                // Create Education entities
                for edu in cvData.education {
                    let education = Education(context: self.context)
                    education.id = UUID()
                    education.institution = edu.institution
                    education.degree = edu.degree
                    education.field = edu.field
                    education.startDate = edu.startDate
                    education.endDate = edu.endDate
                    education.cvInfo = cvInfo
                }
                
                do {
                    try self.context.save()
                    print("Successfully saved CV information to CoreData")
                    return cvInfo
                } catch {
                    print("CoreData save error: \(error)")
                    print("Error details: \(error.localizedDescription)")
                    if let nsError = error as NSError? {
                        print("Domain: \(nsError.domain)")
                        print("Code: \(nsError.code)")
                        print("User Info: \(nsError.userInfo)")
                    }
                    throw CVProcessingError.coreDataError(error)
                }
            }
        } catch {
            print("Context perform error: \(error)")
            throw CVProcessingError.coreDataError(error)
        }
    }
    
    func deleteCV(_ cvInfo: CVInfo) async throws {
        do {
            try await context.perform {
                // Delete all related experiences
                if let experiences = cvInfo.experience as? Set<Experience> {
                    for experience in experiences {
                        self.context.delete(experience)
                    }
                }
                
                // Delete all related education entries
                if let education = cvInfo.education as? Set<Education> {
                    for edu in education {
                        self.context.delete(edu)
                    }
                }
                
                // Delete the CVInfo itself
                self.context.delete(cvInfo)
                
                // Save the changes
                try self.context.save()
                print("Successfully deleted CV and all related data")
            }
        } catch {
            print("Error deleting CV: \(error)")
            print("Error details: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("Domain: \(nsError.domain)")
                print("Code: \(nsError.code)")
                print("User Info: \(nsError.userInfo)")
            }
            throw CVProcessingError.coreDataError(error)
        }
    }
    
    private func cleanJsonString(_ jsonString: String) -> String {
        // First, remove any markdown code block markers and trim
        var cleaned = jsonString
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove any text before the first { and after the last }
        if let startIndex = cleaned.firstIndex(of: "{"),
           let endIndex = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[startIndex...endIndex])
        }
        
        // Remove double-escaped characters
        cleaned = cleaned
            .replacingOccurrences(of: "\\\\", with: "\\")
            .replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\r", with: "\r")
            .replacingOccurrences(of: "\\t", with: "\t")
        
        // Handle special characters that might cause issues
        cleaned = cleaned
            .replacingOccurrences(of: "•", with: "-")  // Replace bullet points with dashes
            .replacingOccurrences(of: "\u{00A0}", with: " ")  // Replace non-breaking spaces with regular spaces
        
        // Remove any remaining control characters
        cleaned = cleaned.components(separatedBy: .controlCharacters).joined()
        
        // Ensure the string starts with { and ends with }
        if !cleaned.hasPrefix("{") {
            cleaned = "{" + cleaned
        }
        if !cleaned.hasSuffix("}") {
            cleaned = cleaned + "}"
        }
        
        // Print the cleaned string for debugging
        print("Final cleaned JSON string: \(cleaned)")
        
        return cleaned
    }
}

// MARK: - Supporting Types
struct CVData: Codable {
    let name: String
    let email: String
    let phone: String
    let summary: String
    let experience: [ExperienceData]
    let education: [EducationData]
    let skills: [String]
}

struct ExperienceData: Codable {
    let company: String
    let position: String
    let startDate: Date
    let endDate: Date?
    let jobDescription: String
}

struct EducationData: Codable {
    let institution: String
    let degree: String?
    let field: String?
    let startDate: Date?
    let endDate: Date?
}


