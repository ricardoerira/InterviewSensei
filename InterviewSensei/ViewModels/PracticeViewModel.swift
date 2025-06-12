import Foundation
import CoreData
import SwiftUI

@MainActor
class PracticeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var quizState: QuizState = .selectingCategory
    @Published var quizQuestions: [QuizQuestion] = []
    @Published var currentQuestionIndex: Int = 0
    @Published var selectedOptionIndex: Int?
    @Published var isAnswerSubmitted: Bool = false
    @Published var feedbackMessage: String?
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var score: Int = 0
    @Published var elapsedTime: TimeInterval = 0
    
    private let geminiService: GeminiService
    private var cvInfo: CVInfo?
    private var selectedAnswers: [Int?] = []
    private var quizStartTime: Date?
    private var timer: Timer?
    
    // MARK: - Initialization
    init(geminiService: GeminiService = GeminiService()) {
        print("[PracticeViewModel] Initializing")
        self.geminiService = geminiService
        loadCVInfo()
    }
    
    // MARK: - Public Methods
    func loadCVInfo() {
        print("[PracticeViewModel] Loading CV info")
        do {
            let context = PersistenceController.shared.container.viewContext
            let request = CVInfo.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CVInfo.updatedAt, ascending: false)]
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            if let latestCV = results.first {
                print("[PracticeViewModel] Found CV info: \(latestCV.name ?? "Unknown")")
                self.cvInfo = latestCV
            } else {
                print("[PracticeViewModel] No CV info found")
            }
        } catch {
            print("[PracticeViewModel] Error loading CV info: \(error.localizedDescription)")
        }
    }
    
    func generateQuiz(for category: QuestionCategory) async {
        print("[PracticeViewModel] Generating quiz for category: \(category.rawValue)")
        quizState = .loading
        
        do {
            let questions = try await generateInterviewQuestions(for: category, using: cvInfo)
            print("[PracticeViewModel] Generated \(questions.count) questions")
            
            await MainActor.run {
                self.quizQuestions = questions
                self.currentQuestionIndex = 0
                self.selectedOptionIndex = nil
                self.isAnswerSubmitted = false
                self.feedbackMessage = nil
                self.score = 0
                self.selectedAnswers = Array(repeating: nil, count: questions.count)
                self.quizState = .practicing
                self.startTimer()
            }
        } catch {
            print("[PracticeViewModel] Error generating questions: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.quizState = .selectingCategory
            }
        }
    }
    
    func selectAnswer(at index: Int) {
        print("[PracticeViewModel] Selected answer at index: \(index)")
        selectedOptionIndex = index
        selectedAnswers[currentQuestionIndex] = index
    }
    
    func submitAnswer() {
        print("[PracticeViewModel] Submitting answer")
        guard let selectedIndex = selectedOptionIndex else { return }
        
        isAnswerSubmitted = true
        let currentQuestion = quizQuestions[currentQuestionIndex]
        
        if selectedIndex == currentQuestion.correctOptionIndex {
            print("[PracticeViewModel] Correct answer")
            score += 1
        } else {
            print("[PracticeViewModel] Incorrect answer")
        }
    }
    
    func nextQuestion() {
        print("[PracticeViewModel] Moving to next question")
        if currentQuestionIndex < quizQuestions.count - 1 {
            currentQuestionIndex += 1
            selectedOptionIndex = selectedAnswers[currentQuestionIndex]
            isAnswerSubmitted = false
            feedbackMessage = nil
        } else {
            print("[PracticeViewModel] Quiz completed with score: \(score)/\(quizQuestions.count)")
            saveQuizResult()
            NotificationCenter.default.post(name: .quizCompleted, object: nil)
            quizState = .completed
        }
    }
    
    func resetQuiz() {
        print("[PracticeViewModel] Resetting quiz")
        stopTimer()
        quizState = .selectingCategory
        quizQuestions = []
        currentQuestionIndex = 0
        selectedOptionIndex = nil
        isAnswerSubmitted = false
        feedbackMessage = nil
        score = 0
        selectedAnswers = []
        elapsedTime = 0
        quizStartTime = nil
    }
    
    // MARK: - Private Methods
    private func startTimer() {
        quizStartTime = Date()
        elapsedTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.quizStartTime else { return }
            self.elapsedTime = Date().timeIntervalSince(startTime)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func saveQuizResult() {
        print("[PracticeViewModel] Saving quiz result")
        stopTimer()
        let context = PersistenceController.shared.container.viewContext
        
        // Create QuizResult
        let quizResult = QuizResult(context: context)
        quizResult.id = UUID()
        quizResult.date = Date()
        quizResult.category = quizQuestions.first?.category ?? "Unknown"
        quizResult.score = Int16(score)
        quizResult.totalQuestions = Int16(quizQuestions.count)
        quizResult.duration = elapsedTime

        // Create QuizQuestionResults
        for (index, question) in quizQuestions.enumerated() {
            let questionResult = QuizQuestionResult(context: context)
            questionResult.id = UUID()
            questionResult.questionText = question.questionText
            questionResult.options = question.options
            questionResult.correctOptionIndex = Int16(question.correctOptionIndex)
            questionResult.selectedOptionIndex = selectedAnswers[index].map { Int16($0) }!
            questionResult.quizResult = quizResult
            quizResult.addToQuestions(questionResult)
        }
        
        // Save to CoreData
        do {
            try context.save()
            print("[PracticeViewModel] Successfully saved quiz result")
        } catch {
            print("[PracticeViewModel] Error saving quiz result: \(error.localizedDescription)")
        }
    }
    
    private func generateInterviewQuestions(for category: QuestionCategory, using cvInfo: CVInfo?) async throws -> [QuizQuestion] {
        print("[PracticeViewModel] Generating questions for category: \(category.rawValue)")
        
        let prompt = """
        Generate 5 multiple-choice interview questions for a \(category.rawValue) interview for senior.
        The candidate has the following details:
        Skills: \(cvInfo?.skills )
        Summary: \(cvInfo?.summary  )

        Return ONLY the raw JSON in the following format, without any markdown formatting or code block indicators:
        {
            "questions": [
                {
                    "questionText": "Question text here",
                    "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
                    "correctOptionIndex": 0
                }
            ]
        }
        
        Make sure the questions are relevant to the candidate's background and experience.
        Do not include any markdown formatting, code block indicators, or additional text.
        Short questions and answers be specific max 50 words by option.
        """
        
        print("[PracticeViewModel] Sending prompt to Gemini")
        let response = try await geminiService.generateResponse(for: prompt)
        print("[PracticeViewModel] Received response from Gemini")
        
        // Clean up the response by removing markdown code block indicators
        let cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanedResponse.data(using: .utf8) else {
            print("[PracticeViewModel] Failed to convert response to data")
            throw NSError(domain: "PracticeViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        print("[PracticeViewModel] Parsing JSON response")
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(QuestionResponse.self, from: jsonData)
            print("[PracticeViewModel] Successfully parsed \(result.questions.count) questions")
            
            // Set the category for each question
            var questions = result.questions
            for i in 0..<questions.count {
                questions[i].category = category.rawValue
            }
            
            return questions
        } catch {
            print("[PracticeViewModel] JSON parsing error: \(error)")
            print("[PracticeViewModel] Raw response: \(response)")
            throw NSError(domain: "PracticeViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse questions: \(error.localizedDescription)"])
        }
    }
}
