import Foundation

enum QuestionCategory: String, CaseIterable, Identifiable {
    case technicalKnowledge = "Technical Knowledge"
    case behavioral = "Behavioral Questions"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .technicalKnowledge:
            return "Test your technical skills and knowledge"
        case .behavioral:
            return "Practice behavioral and situational questions"
        }
    }
    
    var iconName: String {
        switch self {
        case .technicalKnowledge:
            return "laptopcomputer"
        case .behavioral:
            return "person.2.fill"
        }
    }
}

struct QuizQuestion: Codable {
    let questionText: String
    let options: [String]
    let correctOptionIndex: Int
    var category: String?
}

struct QuestionResponse: Codable {
    let questions: [QuizQuestion]
}

enum QuizState {
    case selectingCategory
    case loading
    case practicing
    case completed
}

extension Notification.Name {
    static let quizCompleted = Notification.Name("quizCompleted")
} 