import SwiftUI

struct InterviewWarmupView: View {
    @StateObject var viewModel: InterviewWarmupViewModel
    @State private var showingAnswerDetails: Bool = false

    init() {
        _viewModel = StateObject(wrappedValue: InterviewWarmupViewModel())
    }

    var body: some View {
        VStack(spacing: 20) {
            // Question Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Background question", systemImage: "info.circle")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.purple.opacity(0.1)))
                        .foregroundColor(.purple)
                    Spacer()
                    Text(viewModel.questionProgress)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text(viewModel.currentQuestion)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 5)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)

            // Transcription Area
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    // This space intentionally left blank as the full screen cover will handle the recording visualization
                    Spacer()
                    Button {
                        withAnimation {
                            showingAnswerDetails.toggle()
                        }
                    } label: {
                        Image(systemName: showingAnswerDetails ? "chevron.up" : "chevron.down")
                    }
                }
                .padding(.bottom, 5)

                if !viewModel.transcribedAnswer.isEmpty {
                    Text(viewModel.transcribedAnswer)
                        .font(.body)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)

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
                        .background(viewModel.isRecording ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.isLoadingTips)

                Button(action: {
                    viewModel.generateTipsAndExampleAnswer()
                    showingAnswerDetails = true
                }) {
                    Label("Tip", systemImage: "lightbulb.fill")
                        .font(.title2)
                        .padding(10)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                }
            }
            .padding(.top, 20)

            if showingAnswerDetails {
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        if viewModel.isLoadingTips {
                            ProgressView("Generating tips...")
                                .padding()
                        } else if !viewModel.tips.isEmpty {
                            Text("Tips for answers that questions like this:")
                                .font(.headline)
                            Text(viewModel.tips)
                                .font(.body)
                        }

                        if !viewModel.exampleAnswer.isEmpty {
                            Text("Example Answer:")
                                .font(.headline)
                                .padding(.top, 10)
                            Text(viewModel.exampleAnswer)
                                .font(.body)
                        }

                        if let error = viewModel.errorMessage {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                                .font(.callout)
                                .padding(.top, 10)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.white))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                }
            }

            Spacer()

            // Navigation Buttons
            HStack {
                Button("Previous Question") {
                    viewModel.previousQuestion()
                    showingAnswerDetails = false // Collapse details on question change
                }
                .disabled(viewModel.currentQuestionIndex == 0 || viewModel.isRecording || viewModel.isLoadingTips)

                Spacer()

                Button("Next Question") {
                    viewModel.nextQuestion()
                    showingAnswerDetails = false // Collapse details on question change
                }
                .disabled(viewModel.currentQuestionIndex == viewModel.questions.count - 1 || viewModel.isRecording || viewModel.isLoadingTips)
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .padding()
        .background(Color.gray.opacity(0.1).ignoresSafeArea())
        .fullScreenCover(isPresented: $viewModel.isRecording) {
            RecordingView<InterviewWarmupViewModel>(viewModel: viewModel)
        }
    }
} 
