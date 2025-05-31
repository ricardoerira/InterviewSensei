import SwiftUI

struct PracticeView: View {
    @StateObject private var viewModel = PracticeViewModel()
    @State private var selectedCategory: QuestionCategory?
    @State private var showingQuestionDetail = false
    @State private var selectedQuestion: Question?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(QuestionCategory.allCases, id: \.self) { category in
                    Section(header: Text(category.rawValue)) {
                        ForEach(viewModel.questions.filter { $0.category == category.rawValue }) { question in
                            QuestionRow(question: question)
                                .onTapGesture {
                                    selectedQuestion = question
                                    showingQuestionDetail = true
                                }
                        }
                    }
                }
            }
            .navigationTitle("Practice")
            .sheet(isPresented: $showingQuestionDetail) {
                if let question = selectedQuestion {
                    PracticeQuestionView(question: question)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(QuestionCategory.allCases, id: \.self) { category in
                            Button(category.rawValue) {
                                selectedCategory = category
                                viewModel.loadQuestions(for: category)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}

struct QuestionRow: View {
    let question: Question
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.text ?? "No question text available")
                .font(.headline)
            
            HStack {
                Label(question.difficulty ?? "Unknown", systemImage: "chart.bar")
                Spacer()
                if question.hasResponse {
                    Label("Practiced", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct PracticeQuestionView: View {
    let question: Question
    @StateObject private var viewModel = PracticeQuestionViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Question
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question")
                            .font(.headline)
                        Text(question.text ?? "No question text available")
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    // Recording Controls
                    VStack {
                        if viewModel.isRecording {
                            Text(viewModel.transcript ?? "Listening...")
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                        
                        HStack {
                            Button(action: {
                                if viewModel.isRecording {
                                    viewModel.stopRecording()
                                } else {
                                    viewModel.startRecording()
                                }
                            }) {
                                Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(viewModel.isRecording ? .red : .blue)
                            }
                            
                            if !viewModel.isRecording {
                                Button(action: {
                                    viewModel.generateAIResponse()
                                }) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 64))
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                    }
                    
                    // AI Response
                    if let aiResponse = viewModel.aiResponse {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggested Response")
                                .font(.headline)
                            Text(aiResponse)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    
                    // Tips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tips")
                            .font(.headline)
                        ForEach(viewModel.tips, id: \.self) { tip in
                            HStack(alignment: .top) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text(tip)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Practice Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

class PracticeViewModel: ObservableObject {
    @Published var questions: [Question] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    func loadQuestions(for category: QuestionCategory) {
        // TODO: Implement question loading from Core Data or API
        // For now, using sample questions
        questions = [
            Question(context: PersistenceController.preview.container.viewContext),
            Question(context: PersistenceController.preview.container.viewContext),
            Question(context: PersistenceController.preview.container.viewContext)
        ]
    }
}

class PracticeQuestionViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var transcript: String?
    @Published var aiResponse: String?
    @Published var tips: [String] = [
        "Structure your response with a clear beginning, middle, and end",
        "Use specific examples from your experience",
        "Keep your answer concise and focused",
        "Show enthusiasm and confidence in your delivery"
    ]
    
    func startRecording() {
        // TODO: Implement speech recognition
        isRecording = true
    }
    
    func stopRecording() {
        // TODO: Implement speech recognition stop
        isRecording = false
    }
    
    func generateAIResponse() {
        // TODO: Implement AI response generation
        aiResponse = "Here's a suggested response structure..."
    }
}

struct PracticeView_Previews: PreviewProvider {
    static var previews: some View {
        PracticeView()
    }
} 
