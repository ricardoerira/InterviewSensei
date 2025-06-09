import Foundation
import CoreData
import SwiftUI

@MainActor
class QuizStatisticsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var quizResults: [QuizResult] = []
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var showDeleteConfirmation: Bool = false
    
    // MARK: - Private Properties
    private let viewContext: NSManagedObjectContext
    
    // MARK: - Initialization
    init(viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = viewContext
        loadQuizResults()
        
        // Add observer for quiz completion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleQuizCompleted),
            name: .quizCompleted,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private Methods
    @objc private func handleQuizCompleted() {
        print("[QuizStatisticsViewModel] Quiz completed notification received")
        loadQuizResults()
    }
    
    // MARK: - Public Methods
    func loadQuizResults() {
        print("[QuizStatisticsViewModel] Loading quiz results")
        let request = QuizResult.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \QuizResult.date, ascending: false)]
        
        do {
            quizResults = try viewContext.fetch(request)
            print("[QuizStatisticsViewModel] Loaded \(quizResults.count) quiz results")
        } catch {
            print("[QuizStatisticsViewModel] Error loading quiz results: \(error.localizedDescription)")
            showError = true
            errorMessage = "Failed to load quiz history: \(error.localizedDescription)"
        }
    }
    
    func deleteAllResults() {
        print("[QuizStatisticsViewModel] Deleting all quiz results")
        for result in quizResults {
            viewContext.delete(result)
        }
        
        do {
            try viewContext.save()
            quizResults.removeAll()
            print("[QuizStatisticsViewModel] Successfully deleted all quiz results")
        } catch {
            print("[QuizStatisticsViewModel] Error deleting quiz results: \(error.localizedDescription)")
            showError = true
            errorMessage = "Failed to delete quiz history: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Helper Methods
    func calculateAverageScore() -> Double {
        guard !quizResults.isEmpty else { return 0 }
        let totalScore = quizResults.reduce(0) { $0 + Double($1.score) }
        let totalQuestions = quizResults.reduce(0) { $0 + Double($1.totalQuestions) }
        return totalQuestions > 0 ? (totalScore / totalQuestions) * 100 : 0
    }
    
    func calculateCategoryStats() -> [(category: String, count: Int, averageScore: Double)] {
        var categoryStats: [String: (count: Int, totalScore: Double, totalQuestions: Double)] = [:]
        
        for result in quizResults {
            let category = result.category ?? "Unknown"
            let stats = categoryStats[category] ?? (0, 0, 0)
            categoryStats[category] = (
                stats.count + 1,
                stats.totalScore + Double(result.score),
                stats.totalQuestions + Double(result.totalQuestions)
            )
        }
        
        return categoryStats.map { category, stats in
            let averageScore = stats.totalQuestions > 0 ? (stats.totalScore / stats.totalQuestions) * 100 : 0
            return (category: category, count: stats.count, averageScore: averageScore)
        }.sorted { $0.count > $1.count }
    }
} 