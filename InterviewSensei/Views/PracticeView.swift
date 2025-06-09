import SwiftUI

struct PracticeView: View {
    @StateObject private var viewModel = PracticeViewModel()
    @State private var showingResults = false
    
    var body: some View {
        NavigationView {
            Group {
                switch viewModel.quizState {
                case .selectingCategory:
                    categorySelectionView
                case .loading:
                    loadingView
                case .practicing:
                    quizView
                case .completed:
                    Color.clear
                        .onAppear {
                            showingResults = true
                        }
                }
            }
            .navigationTitle("Practice Interview")
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .sheet(isPresented: $showingResults) {
                QuizResultView(
                    score: viewModel.score,
                    totalQuestions: viewModel.quizQuestions.count,
                    onPracticeAgain: {
                        Task { @MainActor in
                            viewModel.resetQuiz()
                        }
                    },
                    category: viewModel.quizQuestions.first?.category,
                    date: Date(),
                    questions: nil
                )
            }
            .onAppear {
                print("[PracticeView] View appeared")
            }
            .onDisappear {
                print("[PracticeView] View disappeared")
            }
        }
    }
    
    private var categorySelectionView: some View {
        List(QuestionCategory.allCases) { category in
            Button {
                print("[PracticeView] Selected category: \(category.rawValue)")
                Task {
                    await viewModel.generateQuiz(for: category)
                }
            } label: {
                HStack {
                    Image(systemName: category.iconName)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading) {
                        Text(category.rawValue)
                            .font(.headline)
                        Text(category.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Generating questions...")
                .padding(.top)
        }
        .onAppear {
            print("[PracticeView] Loading view appeared")
        }
    }
    
    private var quizView: some View {
        VStack(spacing: 20) {
            if let currentQuestion = viewModel.quizQuestions[safe: viewModel.currentQuestionIndex] {
                // Progress indicator
                ProgressView(value: Double(viewModel.currentQuestionIndex + 1),
                           total: Double(viewModel.quizQuestions.count))
                    .padding(.horizontal)
                    .transition(.opacity)
                
                // Question text
                Text(currentQuestion.questionText)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.2).combined(with: .opacity)
                    ))
                
                // Options
                VStack(spacing: 12) {
                    ForEach(currentQuestion.options.indices, id: \.self) { index in
                        OptionButton(
                            text: currentQuestion.options[index],
                            isSelected: viewModel.selectedOptionIndex == index,
                            isCorrect: viewModel.isAnswerSubmitted ? index == currentQuestion.correctOptionIndex : nil,
                            isDisabled: viewModel.isAnswerSubmitted
                        ) {
                            print("[PracticeView] Option selected at index: \(index)")
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectAnswer(at: index)
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7).delay(Double(index) * 0.1), value: viewModel.currentQuestionIndex)
                    }
                }
                .padding(.horizontal)
                
                // Feedback
                if let feedback = viewModel.feedbackMessage {
                    Text(feedback)
                        .foregroundColor(viewModel.selectedOptionIndex == currentQuestion.correctOptionIndex ? .green : .red)
                        .padding()
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Action buttons
                if viewModel.isAnswerSubmitted {
                    Button("Next Question") {
                        print("[PracticeView] Next question button tapped")
                        withAnimation {
                            viewModel.nextQuestion()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Button("Submit") {
                        print("[PracticeView] Submit button tapped")
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.submitAnswer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.selectedOptionIndex == nil)
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.currentQuestionIndex)
        .onAppear {
            print("[PracticeView] Quiz view appeared - Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.quizQuestions.count)")
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Quiz Complete!")
                .font(.title)
            
            Text("You scored \(viewModel.score) out of \(viewModel.quizQuestions.count)")
                .font(.title2)
            
            Button("Try Another Category") {
                print("[PracticeView] Try another category button tapped")
                viewModel.resetQuiz()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .onAppear {
            print("[PracticeView] Completion view appeared - Final score: \(viewModel.score)/\(viewModel.quizQuestions.count)")
        }
    }
}

struct OptionButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool?
    let isDisabled: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.body)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundColor)
                        .shadow(color: shadowColor, radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 2)
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: { })
    }
    
    private var backgroundColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? .green.opacity(0.2) : .red.opacity(0.2)
        }
        return isSelected ? Color.accentColor.opacity(0.2) : Color(.systemBackground)
    }
    
    private var borderColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? .green : .red
        }
        return isSelected ? .accentColor : Color(.systemGray4)
    }
    
    private var shadowColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? .green.opacity(0.3) : .red.opacity(0.3)
        }
        return isSelected ? .accentColor.opacity(0.3) : Color(.systemGray4)
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
} 