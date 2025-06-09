import Foundation
import SwiftUI
import Combine

class InterviewWarmupViewModel: ObservableObject, RecordingProtocol {
    @Published var questions: [String] = [
        "Can you please tell me a bit about yourself?",
        "What are your strengths and weaknesses?",
        "Why are you interested in this position?",
        "Where do you see yourself in five years?",
        "Do you have any questions for me?"
    ]
    @Published var currentQuestionIndex: Int = 0
    @Published var transcribedAnswer: String = ""
    @Published var tips: String = ""
    @Published var exampleAnswer: String = ""
    @Published var isRecording: Bool = false
    @Published var isLoadingTips: Bool = false
    @Published var errorMessage: String?
    @Published var isAnalyzing = false
    @Published var analysisResult: String? = nil
    @Published public var audioVolume: Float = 0.0

    private var audioTranscriptionService: AudioTranscriptionService
    private var geminiService: GeminiService
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.audioTranscriptionService = AudioTranscriptionService()
        self.geminiService = GeminiService()
        
        // Bind audio service properties
        audioTranscriptionService.$transcribedText
            .receive(on: DispatchQueue.main)
            .assign(to: &$transcribedAnswer)
        
        audioTranscriptionService.$error
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
        
        audioTranscriptionService.$isListening
            .receive(on: DispatchQueue.main)
            .assign(to: &$isRecording)

        setupBindings()
    }

    private func setupBindings() {
        audioTranscriptionService.$transcribedText
            .sink { [weak self] newText in
                self?.transcribedAnswer = newText
                if !newText.isEmpty {
                    self?.generateTipsAndExampleAnswer()
                }
            }
            .store(in: &cancellables)

        audioTranscriptionService.$isListening
            .sink { [weak self] isListening in
                self?.isRecording = isListening
            }
            .store(in: &cancellables)

        audioTranscriptionService.$error
            .sink { [weak self] error in
                self?.errorMessage = error
            }
            .store(in: &cancellables)
        
        audioTranscriptionService.$audioPower
            .sink { [weak self] power in
                self?.audioVolume = power
            }
            .store(in: &cancellables)
    }

    var currentQuestion: String {
        guard questions.indices.contains(currentQuestionIndex) else {
            return "No more questions."
        }
        return questions[currentQuestionIndex]
    }

    var questionProgress: String {
        "\(currentQuestionIndex + 1)/\(questions.count)"
    }

    func startRecording() {
        audioTranscriptionService.startRecording()
        transcribedAnswer = "" // Clear previous answer
        tips = "" // Clear previous tips
        exampleAnswer = "" // Clear previous example answer
        errorMessage = nil // Clear previous error
    }

    func stopRecording() {
        audioTranscriptionService.stopRecording()
    }

    func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            resetForNewQuestion()
        } else {
            // Handle end of warmup
            print("End of warmup session.")
            // Potentially navigate to a summary screen
        }
    }

    func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
            resetForNewQuestion()
        }
    }

    private func resetForNewQuestion() {
        transcribedAnswer = ""
        tips = ""
        exampleAnswer = ""
        errorMessage = nil
        // Any other state resets
    }

     func generateTipsAndExampleAnswer() {
        isLoadingTips = true
        Task {
            do {
                let currentQ = currentQuestion // Capture for async use
                
                // Generate tips
                let tipsPrompt = """
                As an expert interview coach, provide concise and actionable tips for answering the following interview question. Focus on key elements, common pitfalls, and effective structuring (e.g., STAR method if applicable).
                Question: "\(currentQ)"
                Candidate's Answer: "\(transcribedAnswer)"
                ---
                Provide tips based on the candidate's answer and the question. Be specific and actionable.
                """
                let generatedTips = try await geminiService.generateResponse(for: tipsPrompt)
                await MainActor.run {
                    self.tips = generatedTips
                }

                // Generate example answer
                let examplePrompt = """
                As an expert interview coach, provide a concise and strong example answer for the following interview question.
                Question: "\(currentQ)"
                """
                let generatedExample = try await geminiService.generateResponse(for: examplePrompt)
                await MainActor.run {
                    self.exampleAnswer = generatedExample
                }

                await MainActor.run {
                    isLoadingTips = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to generate tips/example: \(error.localizedDescription)"
                    self.isLoadingTips = false
                }
            }
        }
    }
}
