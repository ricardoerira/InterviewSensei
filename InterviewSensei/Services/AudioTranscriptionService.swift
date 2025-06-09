import Speech
import AVFoundation
import Combine

public class AudioTranscriptionService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published public var transcribedText: String = ""
    @Published public var isListening: Bool = false
    @Published public var error: String? = nil
    @Published public var hasMicrophonePermission: Bool = false
    @Published public var audioPower: Float = 0.0

    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    private let openAIAPIKey: String
    private var meteringTimer: Timer?

    public override init() {
        self.openAIAPIKey = Bundle.main.infoDictionary?["OpenAIKey"] as? String ?? ""
        super.init()
        checkMicrophonePermission()
    }

    private func checkMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.hasMicrophonePermission = granted
            }
        }
    }

    public func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.hasMicrophonePermission = granted
                }
                continuation.resume(returning: granted)
            }
        }
    }

    public func startRecording() {
        guard !isListening else {
            return
        }

        transcribedText = ""
        error = nil
        audioPower = 0.0

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            let tempDir = FileManager.default.temporaryDirectory
            audioFileURL = tempDir.appendingPathComponent("interview_audio.m4a")

            guard let url = audioFileURL else {
                self.error = "Failed to create audio file URL"
                return
            }

            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isListening = true

            meteringTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true, block: { [weak self] _ in
                self?.audioRecorder?.updateMeters()
                let power = self?.audioRecorder?.averagePower(forChannel: 0) ?? 0.0
                let normalizedPower = max(0.0, 1.0 + (power / 160.0))
                DispatchQueue.main.async {
                    self?.audioPower = normalizedPower
                }
            })
        } catch {
            self.error = "Failed to start audio recording: \(error.localizedDescription)"
        }
    }

    public func stopRecording() {
        meteringTimer?.invalidate()
        meteringTimer = nil
        audioRecorder?.stop()
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false)

        isListening = false
        audioPower = 0.0

        guard let audioFileURL = audioFileURL, FileManager.default.fileExists(atPath: audioFileURL.path),
              (try? Data(contentsOf: audioFileURL))?.count ?? 0 > 1024 else {
            self.error = "No audio to transcribe."
            return
        }

        Task {
            do {
                let transcription = try await transcribeAudioWithWhisper(fileURL: audioFileURL)
                await MainActor.run {
                    self.transcribedText = transcription
                }
            } catch {
                await MainActor.run {
                    self.error = "Whisper transcription failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func transcribeAudioWithWhisper(fileURL: URL) async throws -> String {
        guard !openAIAPIKey.isEmpty else {
            throw NSError(domain: "AudioTranscriptionService.Whisper", code: -1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API Key is missing."])
        }

        let audioData = try Data(contentsOf: fileURL)
        guard audioData.count > 1024 else {
            return ""
        }

        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var data = Data()

        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("whisper-1".data(using: .utf8)!)
        data.append("\r\n".data(using: .utf8)!)

        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        data.append("en".data(using: .utf8)!)
        data.append("\r\n".data(using: .utf8)!)

        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/mp4\r\n\r\n".data(using: .utf8)!)
        data.append(audioData)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)

        let (responseData, _) = try await URLSession.shared.upload(for: request, from: data)
        if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any],
           let text = json["text"] as? String {
            return text
        } else {
            throw NSError(domain: "AudioTranscriptionService.Whisper", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response from Whisper API."])
        }
    }
} 
