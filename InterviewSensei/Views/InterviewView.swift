import SwiftUI
import Speech

struct InterviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var appleSpeechRecognizer = SpeechRecognizer()
    @StateObject private var googleSpeechRecognizer = GoogleSpeechRecognizer()
    @StateObject private var viewModel: InterviewViewModel
    @State private var settings = InterviewSettings()
    @State private var isGeneratingResponse = false
    
    init() {
        // Initialize the view model with the managed object context
        _viewModel = StateObject(wrappedValue: InterviewViewModel(context: PersistenceController.shared.container.viewContext))
    }

    private var activeSpeechRecognizer: any ObservableObject {
        switch settings.speechRecognitionProvider {
        case .apple:
            return appleSpeechRecognizer
        case .google:
            return googleSpeechRecognizer
        }
    }
    
    private var transcript: String? {
        switch settings.speechRecognitionProvider {
        case .apple:
            return appleSpeechRecognizer.transcript
        case .google:
            return googleSpeechRecognizer.transcript
        }
    }
    
    private var isRecording: Bool {
        switch settings.speechRecognitionProvider {
        case .apple:
            return appleSpeechRecognizer.isRecording
        case .google:
            return googleSpeechRecognizer.isRecording
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if let question = viewModel.currentQuestion {
                    QuestionView(question: $viewModel.questionVoice)
                        .padding()
                    
                    if viewModel.isRecording {
                        RecordingView(transcript: transcript)
                            .padding()
                    }
                    
                    if isGeneratingResponse {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                            Text("Generating response...")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 100)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding()
                    } else {
                        AnswerView(answer: $viewModel.aiResponse)
                            .padding()
                    }
                    
                    HStack {
                        Button(action: {
                            if viewModel.isRecording {
                                switch settings.speechRecognitionProvider {
                                case .apple:
                                    appleSpeechRecognizer.stopRecording()
                                case .google:
                                    googleSpeechRecognizer.stopRecording()
                                }
                                viewModel.isRecording = false
                                viewModel.questionVoice = viewModel.questionDetector.detectQuestions(from: transcript ?? "")
                                Task {
                                    isGeneratingResponse = true
                                    await viewModel.generateAIResponse(for: viewModel.questionVoice ?? "")
                                    isGeneratingResponse = false
                                    viewModel.showingAnswer = true
                                }
                            } else {
                                viewModel.questionVoice = ""
                                switch settings.speechRecognitionProvider {
                                case .apple:
                                    appleSpeechRecognizer.startRecording()
                                case .google:
                                    googleSpeechRecognizer.startRecording()
                                }
                                viewModel.isRecording = true
                            }
                        }) {
                            Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(viewModel.isRecording ? .red : .blue)
                        }
                        .disabled(isGeneratingResponse)
                        
                        if !viewModel.isRecording {
                            Button(action: {
                                Task {
                                    isGeneratingResponse = true
                                    await viewModel.generateAIResponse(for: viewModel.questionVoice ?? "")
                                    isGeneratingResponse = false
                                    viewModel.showingAnswer = true
                                }
                            }) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 64))
                                    .foregroundColor(.purple)
                            }
                            .disabled(isGeneratingResponse)
                        }
                    }
                    
                    Button("Next Question") {
                        viewModel.nextQuestion()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    .disabled(isGeneratingResponse)
                } else {
                    VStack {
                        Text("Ready to Start?")
                            .font(.title)
                            .padding()
                        
                        Button("Start Interview") {
                            viewModel.startInterview()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Interview")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                InterviewSettingsView()
            }
            .sheet(isPresented: $viewModel.showingFeedback) {
                if let response = transcript {
                    FeedbackView(response: response, question: viewModel.currentQuestion!)
                }
            }
            .onChange(of: isRecording) { isRecording in
                viewModel.questionVoice = viewModel.questionDetector.detectQuestions(from: transcript ?? "")
                if !isRecording && !(viewModel.questionVoice == "") {
                    viewModel.isRecording = false
                    viewModel.questionVoice = viewModel.questionDetector.detectQuestions(from: transcript ?? "")
                    Task {
                        isGeneratingResponse = true
                        await viewModel.generateAIResponse(for: viewModel.questionVoice ?? "")
                        isGeneratingResponse = false
                        viewModel.showingAnswer = true
                    }
                }
            }
        }
    }
}

struct QuestionView: View {
    @Binding var question: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question ?? "No question text available")
                .font(.title2)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
          
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}

struct AnswerView: View {
    @Binding var answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI-Generated Response")
                .font(.headline)
                .foregroundColor(.purple)
            
            Text(answer)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
        }
        .padding()
    }
}

struct RecordingView: View {
    let transcript: String?
    
    var body: some View {
        VStack {
            Text(transcript ?? "Listening...")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
        }
    }
}

struct InterviewView_Previews: PreviewProvider {
    static var previews: some View {
        InterviewView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 
