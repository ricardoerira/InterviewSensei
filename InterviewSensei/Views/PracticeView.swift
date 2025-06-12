import SwiftUI

struct PracticeView: View {
    @StateObject private var viewModel = PracticeViewModel()
    @State private var showingResults = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                VStack {
                    switch viewModel.quizState {
                    case .selectingCategory:
                        categorySelectionView
                    case .loading:
                        loadingView  .navigationBarTitleDisplayMode(.inline)
                            .navigationBarBackButtonHidden()
                            .navigationTitle("")

                         
                    case .practicing:
                        quizView
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationTitle("")
                            .padding(.top, 190)
                          
                    case .completed:
                        Color.clear
                            .onAppear {
                                showingResults = true
                            }
                    }
                }

               
                .alert("Error", isPresented: $viewModel.showError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(viewModel.errorMessage ?? "An unknown error occurred")
                }
                .sheet(isPresented: $showingResults, onDismiss: {
                    presentationMode.wrappedValue.dismiss()
                }) {
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
                        questions: nil,
                        duration: viewModel.elapsedTime
                    )
                }
                .onAppear {
                    print("[PracticeView] View appeared")
                }
                .onDisappear {
                    print("[PracticeView] View disappeared")
                }
            }
           
            .foregroundColor(.white)

        } .navigationBarBackButtonHidden()
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
                        .foregroundColor(Color("Blue"))
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
                
            }        .background(Color.white.opacity(0.15))
            .buttonStyle(GlassButtonStyle())

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
                // Timer at top trailing
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(Color("Blue"))
                        Text(formatTime(viewModel.elapsedTime))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.5),
                                                .white.opacity(0.2),
                                                .clear
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Progress indicator
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color("BlueLight"), Color("Blue").opacity(0.9)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 24)
                        let width = geometry.size.width * CGFloat(viewModel.currentQuestionIndex + 1) / CGFloat(max(viewModel.quizQuestions.count, 1))
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.25))
                            .frame(width: width, height: 24)
                            .animation(.easeInOut, value: viewModel.currentQuestionIndex)
                        HStack {
                            Spacer()
                            Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.quizQuestions.count)")
                                .font(.caption).bold()
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                }
                .frame(height: 24)
                .padding(.horizontal)
                .transition(.opacity)
                
                // Question text
                Text(currentQuestion.questionText)
                    .font(.title3).bold()
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
                
                // Action buttons with liquid glass style
                if viewModel.isAnswerSubmitted {
                    Button("Next Question") {
                        print("[PracticeView] Next question button tapped")
                        withAnimation {
                            viewModel.nextQuestion()
                        }
                    }
                    .buttonStyle(GlassButtonStyle())
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Button("Submit") {
                        print("[PracticeView] Submit button tapped")
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.submitAnswer()
                        }
                    }
                    .buttonStyle(GlassButtonStyle(gradient: LinearGradient(colors: [(viewModel.selectedOptionIndex == nil ? Color.gray : Color.green).opacity(0.7), (viewModel.selectedOptionIndex == nil ? Color.gray : Color.green).opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                    .disabled(viewModel.selectedOptionIndex == nil)
                    .opacity(viewModel.selectedOptionIndex == nil ? 0.6 : 1.0)
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                }
                
                Button(action: {
                    viewModel.resetQuiz()
                }) {
                    Image(systemName: "stop.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(20)
                        .background(
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.red.opacity(0.7),
                                                Color.red.opacity(0.5)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Circle()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.5),
                                                .white.opacity(0.2),
                                                .clear
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .padding()
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
            .buttonStyle(GlassButtonStyle())
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
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    ZStack {
                        // Base glass effect
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                        
                        // Gradient overlay for depth
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        backgroundColor.opacity(opacityColor),
                                        backgroundColor.opacity(opacityColor - 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Border gradient
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        backgroundColor.opacity(opacityColor),
                                        backgroundColor.opacity(opacityColor + 0.3),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .cornerRadius(16)
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: { })
    }
    
    private var backgroundColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? .green : .red
        }
        return isSelected ? Color("Blue") : Color.white
    }

    private var opacityColor: Double {
        if let isCorrect = isCorrect {
            return isCorrect ? 0.7 : 0.7
        }
        return isSelected ? 0.7  : 0.2
    }
    
    private var borderColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? .green : .red
        }
        return isSelected ? Color("Blue") : Color(.systemGray4)
    }
    
    private var shadowColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? .green.opacity(0.3) : .red.opacity(0.3)
        }
        return isSelected ? Color("Blue").opacity(0.3) : Color(.systemGray4)
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct PracticeView_Previews: PreviewProvider {
    static var previews: some View {
        PracticeView()
    }
}

private func formatTime(_ timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    let milliseconds = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 10)
    return String(format: "%02d:%02d.%01d", minutes, seconds, milliseconds)
}

struct GlassButtonStyle: ButtonStyle {
    var gradient: LinearGradient = LinearGradient(
        colors: [Color("Blue").opacity(0.7), Color("Blue").opacity(0.5)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    var cornerRadius: CGFloat = 16
    var padding: EdgeInsets = EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
    var font: Font = .headline
    var foreground: Color = .white
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundColor(foreground)
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(gradient)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.5),
                                    .white.opacity(0.2),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}
