import SwiftUI

struct FeedbackView: View {
    let response: String
    let question: Question
    @StateObject private var viewModel = FeedbackViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Question Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question")
                            .font(.headline)
                        Text(question.text ?? "No question text available")
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    // User Response Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Response")
                            .font(.headline)
                        Text(response)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    // AI Feedback Section
                    if let feedback = viewModel.feedback {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AI Feedback")
                                .font(.headline)
                            
                            FeedbackCategoryView(category: "Clarity", score: feedback.clarity)
                            FeedbackCategoryView(category: "Relevance", score: feedback.relevance)
                            FeedbackCategoryView(category: "Confidence", score: feedback.confidence)
                            
                            Text(feedback.suggestions)
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    
                    // AI Suggested Response
                    if let suggestedResponse = viewModel.suggestedResponse {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggested Response")
                                .font(.headline)
                            Text(suggestedResponse)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.generateFeedback(for: response, question: question)
            }
        }
    }
}

struct FeedbackCategoryView: View {
    let category: String
    let score: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(category)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(score * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: score)
                .progressViewStyle(.linear)
                .tint(scoreColor)
        }
        .padding(.vertical, 4)
    }
    
    private var scoreColor: Color {
        switch score {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return .yellow
        default:
            return .red
        }
    }
}

class FeedbackViewModel: ObservableObject {
    @Published var feedback: FeedbackData?
    @Published var suggestedResponse: String?
    @Published var isLoading = false
    @Published var error: Error?
    
    func generateFeedback(for response: String, question: Question) {
        isLoading = true
        
        // TODO: Implement actual AI feedback generation
        // For now, using mock feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.feedback = FeedbackData(
                clarity: 0.8,
                relevance: 0.9,
                confidence: 0.7,
                suggestions: "Overall, your response was clear and well-structured. You effectively communicated your points and maintained relevance to the question. Consider adding more specific examples to strengthen your technical accuracy."
            )
            
            self.suggestedResponse = """
            Here's a suggested response structure:
            
            1. Start with a clear introduction that directly addresses the question
            2. Provide specific examples from your experience
            3. Connect your examples to the role requirements
            4. Conclude with a forward-looking statement
            
            Remember to:
            - Be concise and focused
            - Use concrete examples
            - Show enthusiasm and confidence
            - Maintain professional tone
            """
            
            self.isLoading = false
        }
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackView(
            response: "I have experience in software development and enjoy solving complex problems.",
            question: Question(context: PersistenceController.preview.container.viewContext)
        )
    }
} 
