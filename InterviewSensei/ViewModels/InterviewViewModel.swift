import Foundation
import SwiftUI
import CoreData
import Speech


@MainActor
class InterviewViewModel: ObservableObject {
    @Published var currentQuestion: Question?
    @Published var questionVoice: String? = ""
    @Published var questionDetector = QuestionDetector()
    @Published var isRecording = false
    @Published var isAnalyzing = false
    @Published var showFeedback = false
    @Published var currentFeedback: FeedbackData?
    @Published var isInterviewComplete = false
    @Published var showSettings = false
    @Published var settings = InterviewSettings()
    @Published var questions: [Question] = []
    @Published var currentQuestionIndex = 0
    @Published var isGeneratingResponse = false
    @Published var showingSettings = false
    @Published var showingFeedback = false
    @Published var showingAnswer = false

    @Published var aiResponse: String = ""
    @Published var showTips = false
    @Published var currentTip: String = ""
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let geminiService = GeminiService()
    private let managedObjectContext: NSManagedObjectContext
    private var currentSession: InterviewSession?
    
    init(context: NSManagedObjectContext) {
        self.managedObjectContext = context
        loadQuestions()
    }

    
    private func loadQuestions() {
        // Load questions from Core Data or create initial set
        let request: NSFetchRequest<Question> = Question.fetchRequest()
        do {
            questions = try managedObjectContext.fetch(request)
            if questions.isEmpty {
                // Create initial questions if none exist
                createInitialQuestions()
            }
        } catch {
            print("Error loading questions: \(error)")
        }
    }
    
    private func createInitialQuestions() {
        let initialQuestions = [
            ("Tell me about yourself.", "Behavioral", "Easy"),
            ("What are your greatest strengths?", "Behavioral", "Easy"),
            ("What is your greatest weakness?", "Behavioral", "Medium"),
            ("Why do you want to work here?", "Behavioral", "Medium"),
            ("Where do you see yourself in 5 years?", "Behavioral", "Medium"),
            ("Describe a challenging project you worked on.", "Technical", "Hard"),
            ("How do you handle stress and pressure?", "Behavioral", "Medium"),
            ("What is your leadership style?", "Behavioral", "Hard"),
            ("How do you handle conflict in the workplace?", "Behavioral", "Medium"),
            ("What are your salary expectations?", "Behavioral", "Medium")
        ]
        
        for (text, category, difficulty) in initialQuestions {
            let question = Question(context: managedObjectContext)
            question.id = UUID()
            question.text = text
            question.category = category
            question.difficulty = difficulty
            question.jobRole = "Software Engineer"
            question.timestamp = Date()
            questions.append(question)
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            print("Error saving initial questions: \(error)")
        }
    }
    
    func startInterview() {
        // Create a new interview session
        let session = InterviewSession(context: managedObjectContext)
        session.id = UUID()
        session.date = Date()
        session.jobRole = settings.selectedJobRole
        session.mode = settings.interviewMode.rawValue
        currentSession = session
        
        // Filter questions based on settings
        questions = questions.filter { question in
            settings.selectedCategories.contains(question.category ?? "") &&
            question.jobRole == settings.selectedJobRole
        }
        
        currentQuestionIndex = 0
        currentQuestion = questions.first
        isInterviewComplete = false
        showFeedback = false
    }
    
    func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            DispatchQueue.main.async {
                self.currentQuestion = self.questions[self.currentQuestionIndex]
            }
            showFeedback = false
            currentFeedback = nil
        } else {
            isInterviewComplete = true
        }
    }
    
    func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
            currentQuestion = questions[currentQuestionIndex]
            showFeedback = false
            currentFeedback = nil
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        // Request permissions
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.setupRecording()
                case .denied, .restricted, .notDetermined:
                    print("Speech recognition not authorized")
                @unknown default:
                    print("Unknown authorization status")
                }
            }
        }
    }
    
    private func setupRecording() {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }
        
        // Create and configure the speech recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request")
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                // Update the text view with the results
                print("Transcription: \(result.bestTranscription.formattedString)")
            }
                
            if error != nil {
                self.stopRecording()
            }
        }
        
        // Configure the audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        isRecording = false
        isAnalyzing = true
        
        // Generate feedback
        Task {
            await generateFeedback(for: "User's response")
        }
    }
    
    func generateAIResponse(for question: String) async {
        questionVoice = question
        isGeneratingResponse = true
        defer { isGeneratingResponse = false }
        
        let prompt = """
        As an experienced iOS developer , provide a short and explicific answer to the following interview question:
        "\(question)"
        
        """
        
        do {
            let response = try await geminiService.generateResponse(for: prompt)
            await MainActor.run {
                self.aiResponse = response
            }
        } catch {
            print("Error generating AI response: \(error)")
            await MainActor.run {
                self.aiResponse = "Sorry, I couldn't generate a response at this time."
            }
        }
    }
    
    func generateFeedback(for response: String) async {
        let prompt = """
        Analyze the following interview response and provide constructive feedback:
        "\(response)"
        
        Please evaluate:
        1. Clarity and structure
        2. Relevance to the question
        3. Use of examples
        4. Professional tone
        5. Areas for improvement
        
        Provide specific suggestions for improvement.
        """
        
        do {
            let feedback = try await geminiService.generateResponse(for: prompt)
            await MainActor.run {
                self.currentFeedback = FeedbackData(
                    clarity: 0.8,
                    relevance: 0.9,
                    confidence: 0.85,
                    suggestions: feedback
                )
                self.showFeedback = true
                self.isAnalyzing = false
            }
        } catch {
            print("Error generating feedback: \(error)")
            await MainActor.run {
                self.isAnalyzing = false
            }
        }
    }
    
    func saveResponse(text: String, audioURL: URL?) {
        guard let question = currentQuestion else { return }
        
        let response = Response(context: managedObjectContext)
        response.id = UUID()
        response.text = text
        response.timestamp = Date()
        response.audioURL = audioURL
        response.question = question
        
        // Mark the question as having a response
        question.hasResponse = true
        
        // Create feedback
        if let feedback = currentFeedback {
            let feedbackEntity = Feedback(context: managedObjectContext)
            feedbackEntity.id = UUID()
            feedbackEntity.text = feedback.suggestions
            feedbackEntity.score = feedback.clarity
            feedbackEntity.category = "General"
            feedbackEntity.timestamp = Date()
            feedbackEntity.response = response
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            print("Error saving response: \(error)")
        }
    }
    
    func generateTip() {
        let tips = [
            "Take a moment to think before answering",
            "Use the STAR method for behavioral questions",
            "Keep your answers concise and focused",
            "Provide specific examples from your experience",
            "Show enthusiasm and confidence",
            "Ask clarifying questions if needed",
            "Maintain good eye contact and body language",
            "Be honest about your weaknesses",
            "Research the company before the interview",
            "Follow up with a thank-you note"
        ]
        
        currentTip = tips.randomElement() ?? tips[0]
        showTips = true
    }
}

struct FeedbackData {
    let clarity: Double
    let relevance: Double
    let confidence: Double
    let suggestions: String
} 
