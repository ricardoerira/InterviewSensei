import Foundation
import CoreData

@objc(QuizResult)
public class QuizResult: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var category: String
    @NSManaged public var score: Int16
    @NSManaged public var totalQuestions: Int16
    @NSManaged public var questions: Set<QuizQuestionResult>
}

@objc(QuizQuestionResult)
public class QuizQuestionResult: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var questionText: String
    @NSManaged public var options: [String]
    @NSManaged public var correctOptionIndex: Int16
    @NSManaged public var selectedOptionIndex: Int16?
    @NSManaged public var quizResult: QuizResult
}

extension QuizResult {
    @objc(addQuestionsObject:)
    @NSManaged public func addToQuestions(_ value: QuizQuestionResult)
    
    @objc(removeQuestionsObject:)
    @NSManaged public func removeFromQuestions(_ value: QuizQuestionResult)
    
    @objc(addQuestions:)
    @NSManaged public func addToQuestions(_ values: Set<QuizQuestionResult>)
    
    @objc(removeQuestions:)
    @NSManaged public func removeFromQuestions(_ values: Set<QuizQuestionResult>)
} 