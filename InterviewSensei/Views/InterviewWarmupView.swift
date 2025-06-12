import SwiftUI

struct InterviewWarmupView: View {
    @StateObject var viewModel: InterviewWarmupViewModel
    @State private var showingAnswerDetails: Bool = false

    init() {
        _viewModel = StateObject(wrappedValue: InterviewWarmupViewModel())
    }

    var body: some View {
        ZStack {
            BackgroundView()
            VStack(spacing: 20) {
                // Question Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Background question", systemImage: "info.circle")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [
                                                        Color.purple.opacity(0.5),
                                                        Color.purple.opacity(0.2),
                                                        .clear
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .foregroundColor(.purple)
                        Spacer()
                        Text(viewModel.questionProgress)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    Text(viewModel.currentQuestion)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.top, 5)
                }
                .padding()
                .liquidGlass()
                .padding(.horizontal)

                // Transcription Area
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation {
                                showingAnswerDetails.toggle()
                            }
                        } label: {
                            Image(systemName: showingAnswerDetails ? "chevron.up" : "chevron.down")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
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
                                        )
                                )
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.bottom, 5)

                    if !viewModel.transcribedAnswer.isEmpty {
                        Text(viewModel.transcribedAnswer)
                            .font(.body)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .liquidGlass()
                .padding(.horizontal)

                // Action Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                        } else {
                            viewModel.startRecording()
                        }
                    }) {
                        Label(viewModel.isRecording ? "Done" : "Answer", systemImage: viewModel.isRecording ? "mic.fill" : "checkmark.circle.fill")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                    
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    (viewModel.isRecording ? Color.red : Color("Blue")).opacity(0.7),
                                                    (viewModel.isRecording ? Color.red : Color("Blue")).opacity(0.5)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    RoundedRectangle(cornerRadius: 16)
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
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .disabled(viewModel.isLoadingTips)

                    Button(action: {
                        viewModel.generateTipsAndExampleAnswer()
                        showingAnswerDetails = true
                    }) {
                        Label("Tip", systemImage: "lightbulb.fill")
                            .font(.title2)
                            .padding(10)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                    
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color("Blue").opacity(0.7),
                                                    Color("Blue").opacity(0.5)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    RoundedRectangle(cornerRadius: 16)
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
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.top, 20)

                if showingAnswerDetails {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            if viewModel.isLoadingTips {
                                ProgressView("Generating tips...")
                                    .padding()
                                    .foregroundColor(.white)
                            } else if !viewModel.tips.isEmpty {
                                Text("Tips for answers that questions like this:")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(viewModel.tips)
                                    .font(.body)
                                    .foregroundColor(.white)
                            }

                            if !viewModel.exampleAnswer.isEmpty {
                                Text("Example Answer:")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.top, 10)
                                Text(viewModel.exampleAnswer)
                                    .font(.body)
                                    .foregroundColor(.white)
                            }

                            if let error = viewModel.errorMessage {
                                Text("Error: \(error)")
                                    .foregroundColor(.red)
                                    .font(.callout)
                                    .padding(.top, 10)
                            }
                        }
                        .padding()
                        .liquidGlass()
                        .padding(.horizontal)
                    }
                }

                Spacer()

                // Navigation Buttons
                HStack {
                    Button("Previous Question") {
                        viewModel.previousQuestion()
                        showingAnswerDetails = false
                    }
                    .disabled(viewModel.currentQuestionIndex == 0 || viewModel.isRecording || viewModel.isLoadingTips)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                            
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color("Blue").opacity(0.7),
                                            Color("Blue").opacity(0.5)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            RoundedRectangle(cornerRadius: 16)
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
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .opacity(viewModel.currentQuestionIndex == 0 || viewModel.isRecording || viewModel.isLoadingTips ? 0.6 : 1.0)

                    Spacer()

                    Button("Next Question") {
                        viewModel.nextQuestion()
                        showingAnswerDetails = false
                    }
                    .disabled(viewModel.currentQuestionIndex == viewModel.questions.count - 1 || viewModel.isRecording || viewModel.isLoadingTips)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                            
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color("Blue").opacity(0.7),
                                            Color("Blue").opacity(0.5)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            RoundedRectangle(cornerRadius: 16)
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
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .opacity(viewModel.currentQuestionIndex == viewModel.questions.count - 1 || viewModel.isRecording || viewModel.isLoadingTips ? 0.6 : 1.0)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .padding()
            .fullScreenCover(isPresented: $viewModel.isRecording) {
                RecordingView<InterviewWarmupViewModel>(viewModel: viewModel)
            }
        }
    }
}

struct InterviewWarmupView_Previews: PreviewProvider {
    static var previews: some View {
        InterviewWarmupView()
    }
}
