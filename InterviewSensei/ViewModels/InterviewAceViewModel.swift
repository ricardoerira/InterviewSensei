import Speech
import AVFoundation
import CoreData

@MainActor
class InterviewAceViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isListening = false
    @Published var transcribedText = ""
    @Published var generatedAnswer = ""
    @Published var isProcessing = false
    @Published var error: String?
    

    
    private func getCVInfoContext() -> String {
        // Fetch only the summary field from the latest CVInfo entity in Core Data
        let context = PersistenceController.shared.container.viewContext
     

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CVInfo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            if let cvInfo = try context.fetch(fetchRequest).first {
                let summary = cvInfo.value(forKey: "summary") as? String ?? ""
                print("[InterviewAceViewModel] Loaded CVInfo summary from Core Data: \(summary)")
                return summary.isEmpty ? "No CV summary available." : summary
            } else {
                print("[InterviewAceViewModel] No CVInfo entity found in Core Data.")
                return "No CV summary available."
            }
        } catch {
            print("[InterviewAceViewModel] Error fetching CVInfo from Core Data: \(error.localizedDescription)")
            return "No CV summary available."
        }
    }
    // ...existing code...oEngine = AVAudioEngine() // Replaced by AVAudioRecorder for Whisper
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    private let synthesizer = AVSpeechSynthesizer()
    // private var identifiedFirstSpeakerID: String? = nil // Whisper API doesn't provide speaker IDs
    private let geminiAPIKey: String
    private let openAIAPIKey: String // For Whisper
    
    // MARK: - Initialization
    init() {
        self.geminiAPIKey = Bundle.main.infoDictionary?["GeminiAPIKey"] as? String ?? ""
        self.openAIAPIKey = Bundle.main.infoDictionary?["OpenAIKey"] as? String ?? "" // Ensure this key is in your Info.plist
        print("[InterviewAceViewModel] Initialized. Gemini Key: \(self.geminiAPIKey.isEmpty ? "EMPTY" : "SET"), OpenAI Key: \(self.openAIAPIKey.isEmpty ? "EMPTY" : "SET")")
        // SFSpeechRecognizer authorization is no longer primary, but good to keep if you might use SFSpeech for other things.
        // For Whisper, we mainly need microphone permission, handled by AVAudioSession.
        requestMicrophonePermission()
    }
    
    // MARK: - Setup Methods
    private func requestMicrophonePermission() {
        print("[InterviewAceViewModel] Requesting microphone permission")
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            Task { @MainActor in
                if granted {
                    print("[InterviewAceViewModel] Microphone permission granted")
                    self.error = nil
                } else {
                    print("[InterviewAceViewModel] Microphone permission denied")
                    self.error = "Microphone permission denied. Please enable it in Settings."
                }
            }
        }
    }
    
    // MARK: - Public Methods
    func startListening() {
        print("[InterviewAceViewModel] startListening called")
        guard !isListening else {
            print("[InterviewAceViewModel] Already listening, returning")
            return
        }
        
        // Reset state
        transcribedText = ""
        generatedAnswer = ""
        error = nil
        // identifiedFirstSpeakerID = nil // Not used with Whisper
        
        // Configure audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("[InterviewAceViewModel] Audio session configured")
        } catch {
            self.error = "Failed to set up audio session: \(error.localizedDescription)"
            print("[InterviewAceViewModel] Error setting up audio session: \(error.localizedDescription)")
            return
        }
        
        // Setup for recording
        let tempDir = FileManager.default.temporaryDirectory
        audioFileURL = tempDir.appendingPathComponent("interview_audio.m4a")
        
        guard let url = audioFileURL else {
            self.error = "Failed to create audio file URL"
            print("[InterviewAceViewModel] Error: Failed to create audio file URL")
            return
        }
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000, // Whisper works well with 16000, but 12000 is common too
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            isListening = true
            print("[InterviewAceViewModel] Recording started to: \(url.path)")
        } catch {
            self.error = "Failed to start audio recording: \(error.localizedDescription)"
            print("[InterviewAceViewModel] Error starting audio recording: \(error.localizedDescription)")
            return
        }
    }
    
    func stopListening() {
        print("[InterviewAceViewModel] stopListening called")
        audioRecorder?.stop()
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false) // Deactivate audio session
        
        isListening = false
        print("[InterviewAceViewModel] Recording stopped.")
        
        guard let audioFileURL = audioFileURL, FileManager.default.fileExists(atPath: audioFileURL.path),
              (try? Data(contentsOf: audioFileURL))?.count ?? 0 > 1024 else {
            print("[InterviewAceViewModel] Audio file is empty or missing, skipping transcription.")
            self.error = "No audio to transcribe."
            return
        }
        
        // Transcribe with Whisper
        Task {
            do {
                isProcessing = true // Indicate processing for transcription
                print("[InterviewAceViewModel] Transcribing with Whisper...")
                let transcription = try await transcribeAudioWithWhisper(fileURL: audioFileURL)
                self.transcribedText = transcription
                print("[InterviewAceViewModel] Whisper transcription: \(transcription)")
                isProcessing = false // Transcription done
                
                if !transcription.isEmpty {
                    processQuestion(transcription)
                } else {
                    print("[InterviewAceViewModel] Whisper returned empty transcription.")
                    self.error = "Could not understand audio."
                }
            } catch {
                self.error = "Whisper transcription failed: \(error.localizedDescription)"
                print("[InterviewAceViewModel] Error during Whisper transcription: \(error.localizedDescription)")
                isProcessing = false
            }
        }
    }
    
    // MARK: - Private Methods
    private func processQuestion(_ question: String) {
        print("[InterviewAceViewModel] processQuestion called with: \(question)")
        guard !question.isEmpty else {
            print("[InterviewAceViewModel] Question is empty, returning")
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                let answer = try await callGeminiAPI(for: question)
                self.generatedAnswer = answer
                self.isProcessing = false
                print("[InterviewAceViewModel] Generated answer: \(answer)")
            } catch {
                self.error = "Failed to generate answer: \(error.localizedDescription)"
                self.isProcessing = false
                print("[InterviewAceViewModel] Error generating answer: \(error.localizedDescription)")
            }
        }
    }
    
    private func callGeminiAPI(for question: String) async throws -> String {
        print("[InterviewAceViewModel] callGeminiAPI called for question: \(question)")

        // Example: Add context from CVInfo (replace with your actual CVInfo usage)
        let cvInfo = getCVInfoContext() // Implement this method to return a string with relevant CV context

        let prompt = """
        You are an expert technical interviewer. The following is the candidate's CV context:

        \(cvInfo)

        Based on the candidate's background, provide a concise, accurate, and professional answer to the following technical interview question. Keep the response brief and focused on key points.

        Question: \(question)
        """

        // Reuse GeminiService for API call
        let answer = try await GeminiService().generateResponse(for: prompt)
        print("[InterviewAceViewModel] Received answer from GeminiService")
        return answer
    }
    
    
    // MARK: - Whisper Transcription
    private func transcribeAudioWithWhisper(fileURL: URL) async throws -> String {
        guard !openAIAPIKey.isEmpty else {
            throw NSError(domain: "InterviewAceViewModel.Whisper", code: -1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API Key is missing."])
        }

        // Check file size before uploading
        let audioData = try Data(contentsOf: fileURL)
        guard audioData.count > 1024 else {
            print("[InterviewAceViewModel] Audio file too small, skipping Whisper API call.")
            return ""
        }

        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var data = Data()

        // Add model part
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("whisper-1".data(using: .utf8)!)
        data.append("\r\n".data(using: .utf8)!)

        // Add language part
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        data.append("en".data(using: .utf8)!)
        data.append("\r\n".data(using: .utf8)!)

        // Add response_format part for plain text (smaller response)
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        data.append("text".data(using: .utf8)!)
        data.append("\r\n".data(using: .utf8)!)

        // Add file data part
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        data.append(audioData)
        data.append("\r\n".data(using: .utf8)!)

        data.append("--\(boundary)--\r\n".data(using: .utf8)!)

        let (responseData, response) = try await URLSession.shared.upload(for: request, from: data)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let responseString = String(data: responseData, encoding: .utf8) ?? "No response data"
            print("[InterviewAceViewModel] Whisper API Error: Status Code \((response as? HTTPURLResponse)?.statusCode ?? -1), Response: \(responseString)")
            throw NSError(domain: "InterviewAceViewModel.Whisper", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Whisper API request failed. Response: \(responseString)"])
        }

        // Since we requested "text" format, the response is plain text
        let transcription = String(data: responseData, encoding: .utf8) ?? ""
        return transcription.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

