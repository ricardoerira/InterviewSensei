import Foundation

struct InterviewSettings {
    var selectedJobRole: String = "Software Engineer"
    var selectedCategories: Set<String> = ["Behavioral", "Technical"]
    var interviewMode: InterviewMode = .practice
    var selectedExperienceLevel: String = "Mid-Level"
    var selectedVoice: String = "en-US"
    var enableVoiceFeedback: Bool = true
    var speechRecognitionProvider: SpeechRecognitionProvider = .google
}



enum SpeechRecognitionProvider: String, CaseIterable {
    case apple = "Apple Speech"
    case google = "Google Cloud"
}



