import Foundation
import Speech
import AVFoundation

class SpeechRecognizer: ObservableObject {
    @Published var transcript: String?
    @Published var confidence: Float?
    @Published var isRecording = false
    @Published var error: Error?

    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    private var silenceTimer: Timer?
    private var initialGraceTimer: Timer?
    
    private let silenceDuration: TimeInterval = 2.0
    private let initialSilenceGracePeriod: TimeInterval = 5.0
    private let volumeThreshold: Float = -30.0  // Adjust based on testing
    
    private var isInInitialGracePeriod = true
    
    init() {
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status != .authorized {
                    self?.error = NSError(domain: "SpeechRecognizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition permission denied"])
                }
            }
        }
    }
    
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
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.error = error
                self.stopRecording()
                return
            }

            if let result = result {
                let isFinal = result.isFinal

                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                    self.confidence = result.bestTranscription.segments.last?.confidence
                }
                
                if !self.isInInitialGracePeriod {
                    self.resetSilenceTimer()
                }

                if isFinal {
                    self.stopRecording()
                }
            }
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        let bufferSize: AVAudioFrameCount = 1024

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.detectAudioVolume(buffer: buffer)
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
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
        
        initialGraceTimer?.invalidate()
        silenceTimer?.invalidate()
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
            print("Silence detected. Stopping recording.")
            self?.stopRecording()
        }
    }

    private func resetSilenceTimer() {
        guard !isInInitialGracePeriod else { return }
        print("Silence timer reset.")
        startSilenceTimer()
    }

    /// Detect audio volume and reset silence timer if volume exceeds threshold
    private func detectAudioVolume(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?.pointee else { return }

        let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))

        let decibels = 20 * log10(rms)
        print("Audio Level: \(decibels) dB")

        if decibels > volumeThreshold {
            print("Audio detected above threshold. Resetting silence timer.")
            resetSilenceTimer()
        }
    }
}
