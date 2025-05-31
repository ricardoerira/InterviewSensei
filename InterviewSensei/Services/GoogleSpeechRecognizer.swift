import Foundation
import AVFoundation

class GoogleSpeechRecognizer: ObservableObject {
    @Published var transcript: String?
    @Published var confidence: Float?
    @Published var isRecording = false
    @Published var error: Error?
    
    private var audioEngine = AVAudioEngine()
    private var audioData: Data?
    private let apiKey = "AIzaSyDDA8ScbcNxepNqK3Y63-0TJ0EmoLZPVBQ"
    private let baseURL = "https://speech.googleapis.com/v1/speech:recognize"
    
    private var silenceTimer: Timer?
    private var initialGraceTimer: Timer?
    private var lastAudioLevel: Float = -160.0 // Start with silence level
    
    private let silenceDuration: TimeInterval = 4.0
    private let initialSilenceGracePeriod: TimeInterval = 5.0
    private let volumeThreshold: Float = -50.0 // Adjusted threshold for better silence detection
    private let silenceThreshold: Float = -60.0 // New threshold for silence detection
    
    private var isInInitialGracePeriod = true
    private var consecutiveSilenceFrames = 0
    private let requiredSilenceFrames = 10 // Number of consecutive silent frames to trigger silence
    
    func startRecording() {
        guard !isRecording else { return }
        stopRecording()
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = error
            return
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        let bufferSize: AVAudioFrameCount = 1024
        
        audioData = Data()
        consecutiveSilenceFrames = 0
        lastAudioLevel = -160.0
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            let channelData = buffer.floatChannelData?[0]
            let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
            
            // Convert audio buffer to Data
            let audioBuffer = Data(bytes: channelDataArray, count: channelDataArray.count * MemoryLayout<Float>.size)
            self.audioData?.append(audioBuffer)
            
            self.detectAudioVolume(buffer: buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecording = true
            isInInitialGracePeriod = true
            startInitialGraceTimer()
        } catch {
            self.error = error
            stopRecording()
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false
        
        initialGraceTimer?.invalidate()
        silenceTimer?.invalidate()
        
        if let audioData = audioData {
            transcribeAudio(audioData: audioData)
        }
    }
    
    private func transcribeAudio(audioData: Data) {
        print("Attempting to transcribe audio data of size: \(audioData.count) bytes")
        let base64Audio = audioData.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "config": [
                    "encoding": "LINEAR16",
                    "sampleRateHertz": 16000,
                    "languageCode": "en-US",
                    "enableAutomaticPunctuation": true,
                    "diarizationConfig": [ // Ensure this nesting exists
                        "enableSpeakerDiarization": true,
                        "minSpeakerCount": 2, // Make sure you're using min/maxSpeakerCount
                        "maxSpeakerCount": 2
                    ]
                ],
            "audio": [
                "content": base64Audio
            ]
        ]
        
        guard let url = URL(string: baseURL) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("\(apiKey)", forHTTPHeaderField: "X-Goog-Api-Key")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            self.error = error
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.error = error
                }
                print("API request error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else { 
                print("API request returned no data.")
                return 
            }
            
            print("Raw API response data received: \(String(data: data, encoding: .utf8) ?? "Unable to decode data as UTF-8")")

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let firstResult = results.first,
                   let alternatives = firstResult["alternatives"] as? [[String: Any]],
                   let firstAlternative = alternatives.first {
                    
                    print("Successfully parsed JSON response.")
                    print("First alternative: \(firstAlternative)")

                    if let words = firstAlternative["words"] as? [[String: Any]] {
                        print("Word: \(words)")

                        var interviewerTranscript = ""
                        var lastSpeakerTag = -1 // Keep track of the last speaker tag
                        
                        for wordInfo in words {
                            // Print each word and its speaker tag for debugging diarization
                            if let word = wordInfo["word"] as? String,
                               let speakerTag = wordInfo["speakerTag"] as? Int {
                                print("Word: \(word), Speaker Tag: \(speakerTag)")
                            }
                            
                            if let word = wordInfo["word"] as? String,
                               let speakerTag = wordInfo["speakerTag"] as? Int {
                                
                                // Append a space before the word if the speaker changes or it's not the first word
                                if lastSpeakerTag != -1 && lastSpeakerTag != speakerTag && interviewerTranscript != "" {
                                    interviewerTranscript += " "
                                }
                                
                                if speakerTag == 1 { // Assuming speakerTag 1 is the interviewer
                                    interviewerTranscript += word
                                }
                                lastSpeakerTag = speakerTag
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self?.transcript = interviewerTranscript
                            // Note: Confidence might not be directly available per speaker segment in this structure, 
                            // so we'll keep the overall confidence if needed or adjust as per API response details.
                            self?.confidence = firstAlternative["confidence"] as? Float // Use overall confidence for now
                        }
                    } else {
                        // Handle cases where 'words' array is not present (e.g., no speech recognized)
                        DispatchQueue.main.async {
                            self?.transcript = nil
                            self?.confidence = nil
                            print("No words array found in transcription response.")
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.error = error
                }
            }
        }.resume()
    }
    
    private func startInitialGraceTimer() {
        initialGraceTimer?.invalidate()
        initialGraceTimer = Timer.scheduledTimer(withTimeInterval: initialSilenceGracePeriod, repeats: false) { [weak self] _ in
            self?.isInInitialGracePeriod = false
            self?.startSilenceTimer()
        }
    }
    
    private func startSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceDuration, repeats: false) { [weak self] _ in
            self?.stopRecording()
        }
    }
    
    private func resetSilenceTimer() {
        guard !isInInitialGracePeriod else { return }
        consecutiveSilenceFrames = 0
        startSilenceTimer()
    }
    
    private func detectAudioVolume(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?.pointee else { return }
        
        let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        
        let decibels = 20 * log10(rms)
        lastAudioLevel = decibels
        
        // Check for silence
        if decibels < silenceThreshold {
            consecutiveSilenceFrames += 1
            if consecutiveSilenceFrames >= requiredSilenceFrames {
                print("Silence detected. Stopping recording.")
                stopRecording()
            }
        } else {
            consecutiveSilenceFrames = 0
            if decibels > volumeThreshold {
                resetSilenceTimer()
            }
        }
    }
} 
