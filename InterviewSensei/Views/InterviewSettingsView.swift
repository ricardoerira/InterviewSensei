import SwiftUI

struct InterviewSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = InterviewSettingsViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                InterviewModeSection(mode: $viewModel.selectedMode)
                JobRoleSection(role: $viewModel.selectedRole)
                ExperienceLevelSection(level: $viewModel.selectedLevel)
                QuestionCategoriesSection(categories: $viewModel.selectedCategories)
                VoiceSettingsSection(
                    voice: $viewModel.selectedVoice,
                    enableFeedback: $viewModel.enableVoiceFeedback
                )
                AISettingsSection(
                    enableRealTime: $viewModel.enableRealTimeFeedback,
                    enableSample: $viewModel.enableSampleAnswers,
                    speechProvider: $viewModel.speechProvider
                )
            }
            .navigationTitle("Interview Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Section Views
private struct InterviewModeSection: View {
    @Binding var mode: InterviewMode
    
    var body: some View {
        Section(header: Text("Interview Mode")) {
            Picker("Mode", selection: $mode) {
                ForEach(InterviewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
        }
    }
}

private struct JobRoleSection: View {
    @Binding var role: JobRole
    
    var body: some View {
        Section(header: Text("Job Role")) {
            Picker("Role", selection: $role) {
                ForEach(JobRole.allCases, id: \.self) { role in
                    Text(role.rawValue).tag(role)
                }
            }
        }
    }
}

private struct ExperienceLevelSection: View {
    @Binding var level: ExperienceLevel
    
    var body: some View {
        Section(header: Text("Experience Level")) {
            Picker("Level", selection: $level) {
                ForEach(ExperienceLevel.allCases, id: \.self) { level in
                    Text(level.rawValue).tag(level)
                }
            }
        }
    }
}

private struct QuestionCategoriesSection: View {
    @Binding var categories: [QuestionCategory: Bool]
    
    var body: some View {
        Section(header: Text("Question Categories")) {
            ForEach(QuestionCategory.allCases, id: \.self) { category in
                Toggle(category.rawValue, isOn: Binding(
                    get: { categories[category] ?? false },
                    set: { categories[category] = $0 }
                ))
            }
        }
    }
}

private struct VoiceSettingsSection: View {
    @Binding var voice: VoiceOption
    @Binding var enableFeedback: Bool
    
    var body: some View {
        Section(header: Text("Voice Settings")) {
            Picker("Voice", selection: $voice) {
                ForEach(VoiceOption.allCases, id: \.self) { voice in
                    Text(voice.rawValue).tag(voice)
                }
            }
            Toggle("Enable Voice Feedback", isOn: $enableFeedback)
        }
    }
}

private struct AISettingsSection: View {
    @Binding var enableRealTime: Bool
    @Binding var enableSample: Bool
    @Binding var speechProvider: SpeechRecognitionProvider
    
    var body: some View {
        Section(header: Text("AI Settings")) {
            Toggle("Real-time Feedback", isOn: $enableRealTime)
            Toggle("Generate Sample Answers", isOn: $enableSample)
            Picker("Speech Recognition", selection: $speechProvider) {
                ForEach(SpeechRecognitionProvider.allCases, id: \.self) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
        }
    }
}

// MARK: - View Model
class InterviewSettingsViewModel: ObservableObject {
    @Published var selectedMode: InterviewMode = .mock
    @Published var selectedRole: JobRole = .softwareEngineer
    @Published var selectedLevel: ExperienceLevel = .intermediate
    @Published var selectedCategories: [QuestionCategory: Bool] = [
        .behavioral: true,
        .technical: true,
        .problemSolving: true,
        .leadership: true,
        .communication: true
    ]
    @Published var selectedVoice: VoiceOption = .default
    @Published var enableVoiceFeedback = true
    @Published var enableRealTimeFeedback = true
    @Published var enableSampleAnswers = true
    @Published var speechProvider: SpeechRecognitionProvider
    
    private let speechProviderKey = "speechRecognitionProvider"
    
    init() {
        // Load settings from UserDefaults
        if let savedProvider = UserDefaults.standard.string(forKey: speechProviderKey), 
           let provider = SpeechRecognitionProvider(rawValue: savedProvider) {
            self.speechProvider = provider
        } else {
            self.speechProvider = .google // Default to Google if no setting is saved
        }
    }
    
    func saveSettings() {
        // Save settings to UserDefaults
        UserDefaults.standard.set(speechProvider.rawValue, forKey: speechProviderKey)
        print("Speech recognition provider saved: \(speechProvider.rawValue)")
    }
}

// MARK: - Enums
enum InterviewMode: String, CaseIterable {
    case mock = "Mock Interview"
    case practice = "Practice Mode"
}

enum JobRole: String, CaseIterable {
    case softwareEngineer = "Software Engineer"
    case productManager = "Product Manager"
    case dataScientist = "Data Scientist"
    case uxDesigner = "UX Designer"
    case projectManager = "Project Manager"
}

enum ExperienceLevel: String, CaseIterable {
    case entry = "Entry Level"
    case intermediate = "Intermediate"
    case senior = "Senior"
    case lead = "Lead"
}

enum QuestionCategory: String, CaseIterable {
    case behavioral = "Behavioral"
    case technical = "Technical"
    case problemSolving = "Problem Solving"
    case leadership = "Leadership"
    case communication = "Communication"
    case cultureFit = "Culture Fit"
}

enum VoiceOption: String, CaseIterable {
    case `default` = "Default"
    case male = "Male"
    case female = "Female"
}

// MARK: - Preview
struct InterviewSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        InterviewSettingsView()
    }
} 
