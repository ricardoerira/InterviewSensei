import Speech
import AVFoundation
import CoreData
import Combine

protocol RecordingProtocol: ObservableObject, AnyObject {
    var isRecording: Bool { get }
    var audioVolume: Float { get }
    func startRecording()
    func stopRecording()
}

@MainActor
class InterviewAceViewModel: ObservableObject, RecordingProtocol {
    // MARK: - Published Properties
    @Published var transcribedText = ""
    @Published var generatedAnswer = ""
    @Published var isProcessing = false
    @Published var isRecording = false
    @Published var error: String?
    @Published var audioVolume: Float = 0.0

    private var audioTranscriptionService: AudioTranscriptionService
    private var geminiService: GeminiService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        self.audioTranscriptionService = AudioTranscriptionService()
        self.geminiService = GeminiService()
        setupBindings()
        // For Whisper, we mainly need microphone permission, handled by AVAudioSession.
        Task {
           await audioTranscriptionService.requestMicrophonePermission()
        }
    }
    
    private func setupBindings() {
        audioTranscriptionService.$transcribedText
            .sink { [weak self] newText in
                self?.transcribedText = newText
                if !newText.isEmpty {
                    self?.processQuestion(newText)
                }
            }
            .store(in: &cancellables)

        audioTranscriptionService.$isListening
            .sink { [weak self] isListening in
                self?.isRecording = isListening
                // Only set isProcessing to true if not recording
                if let self = self, !isListening {
                    self.isProcessing = true
                }
            }
            .store(in: &cancellables)

        audioTranscriptionService.$error
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
        
        audioTranscriptionService.$audioPower
            .sink { [weak self] power in
                self?.audioVolume = power
            }
            .store(in: &cancellables)
    }

    private func getCVInfoContext() -> String {
        let context = PersistenceController.shared.container.viewContext
     
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CVInfo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            if let cvInfo = try context.fetch(fetchRequest).first {
                let summary = cvInfo.value(forKey: "summary") as? String ?? ""
                return summary.isEmpty ? "No CV summary available." : summary
            } else {
                return "No CV summary available."
            }
        } catch {
            return "No CV summary available."
        }
    }
    
    // MARK: - Public Methods
    func startRecording() {
        generatedAnswer = ""
        error = nil
        audioTranscriptionService.startRecording()
    }
    
    func stopRecording() {
        audioTranscriptionService.stopRecording()
    }
    
    // MARK: - Private Methods
    private func processQuestion(_ question: String) {
        guard !question.isEmpty else {
            return
        }
        
        Task {
            do {
                let cvInfo = getCVInfoContext()
                let prompt = """
                You are an expert technical interviewer. The following is the candidate's CV context:

                \(cvInfo)

                Based on the candidate's background, provide a concise, accurate, and professional answer to the following technical interview question. Keep the response brief and focused on key points.

                Question: \(question)
                """
                let answer = try await geminiService.generateResponse(for: prompt)
                self.generatedAnswer = answer
            } catch {
                self.error = "Failed to generate answer: \(error.localizedDescription)"
            }
        }
    }
}

