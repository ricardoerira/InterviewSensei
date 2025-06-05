import Foundation
import CoreData
import SwiftUI
import PDFKit

enum CVProcessingError: LocalizedError {
    case invalidResponse
    case invalidFileFormat
    case jsonParsingError(String)
    case coreDataError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Failed to get a valid response from the AI service"
        case .invalidFileFormat:
            return "The file format is not supported. Please use a text or PDF file"
        case .jsonParsingError(let details):
            return "Failed to parse the AI service response: \(details)"
        case .coreDataError(let error):
            return "Failed to save CV information: \(error.localizedDescription)"
        }
    }
}

@MainActor
class CVImportViewModel: ObservableObject {
    @Published var cvInfo: CVInfo?
    @Published var isImporting = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showSuccess = false
    @Published var importedCV: CVInfo?
    @Published var isProcessing = false

    private let cvProcessingService: CVProcessingService
    private let geminiService: GeminiService
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        self.geminiService = GeminiService()
        self.cvProcessingService = CVProcessingService(
            geminiService: geminiService,
            context: context
        )
    }
    
    func processCVFile(_ file: URL) async throws -> CVInfo {
        let fileContent: String
        
        if file.pathExtension.lowercased() == "pdf" {
            // Handle PDF file
            guard let pdf = PDFDocument(url: file) else {
                throw CVProcessingError.invalidFileFormat
            }
            
            var text = ""
            for i in 0..<pdf.pageCount {
                if let page = pdf.page(at: i),
                   let pageText = page.string {
                    text += pageText + "\n"
                }
            }
            
            if text.isEmpty {
                throw CVProcessingError.invalidFileFormat
            }
            
            fileContent = text
        } else {
            // Handle text file
            do {
                fileContent = try String(contentsOf: file, encoding: .utf8)
            } catch {
                throw CVProcessingError.invalidFileFormat
            }
        }
        
        // Process CV using Gemini
        let processedCVInfo = try await cvProcessingService.processCV(fileContent)
        cvInfo = processedCVInfo
        return processedCVInfo
    }
    
    func generateInterviewQuestions() async throws -> [String] {
        guard let cvInfo = cvInfo else {
            throw CVProcessingError.invalidResponse
        }
        
        // Create prompt for Gemini to generate questions
        let prompt = """
        Based on the following CV information, generate 5 relevant technical interview questions that would be appropriate for this candidate's experience level and background. Focus on their specific skills and experience areas.
        
        Name: \(String(describing: cvInfo.name))
        Summary: \(cvInfo.summary ?? "N/A")
        Experience: \(cvInfo.experience?.allObjects.compactMap { $0 as? Experience }.map { "- \($0.position ?? "") at \($0.company ?? "")" }.joined(separator: "\n") ?? "N/A")
        Skills: \(cvInfo.skills?.joined(separator: ", ") ?? "N/A")
        
        Format the response as a JSON array of strings.
        """
        
        // Get response from Gemini
        let response = try await geminiService.generateResponse(for: prompt)
        
        // Parse JSON response
        guard let jsonData = response.data(using: String.Encoding.utf8) else {
            throw CVProcessingError.invalidResponse
        }
        
        do {
            let questions = try JSONDecoder().decode([String].self, from: jsonData)
            return questions
        } catch {
            throw CVProcessingError.jsonParsingError(error.localizedDescription)
        }
    }
    
    func deleteCV() async {
        guard let cv = importedCV else { return }
        
        do {
            try await cvProcessingService.deleteCV(cv)
            await MainActor.run {
                self.importedCV = nil
                self.showSuccess = true
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to delete CV: \(error.localizedDescription)"
                self.showError = true
            }
        }
    }
    
    func importCV() {
        // ...existing import logic...
    }

    func handleCVProcessingError(_ error: Error) {
        self.errorMessage = error.localizedDescription
        // Try to fetch the latest saved CV from Core Data if available
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest = NSFetchRequest<CVInfo>(entityName: "CVInfo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            if let savedCV = try context.fetch(fetchRequest).first {
                self.importedCV = savedCV
                print("[CVImportViewModel] Loaded saved CV after error: \(savedCV.summary ?? "")")
            } else {
                self.importedCV = nil
                print("[CVImportViewModel] No saved CV found after error.")
            }
        } catch {
            self.importedCV = nil
            print("[CVImportViewModel] Failed to fetch saved CV after error: \(error.localizedDescription)")
        }
    }
}

