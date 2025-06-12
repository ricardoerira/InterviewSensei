import SwiftUI

struct InterviewAceView: View {
    @StateObject private var viewModel = InterviewAceViewModel()
    
    var body: some View {
        ZStack {
            BackgroundView()
            VStack(spacing: 20) {
                // Header
              
                
                  
                // Transcribed Text and Generated Answer Container
                VStack(spacing: 4) { // Minimal spacing between elements
                    // Transcribed Text
                    ScrollView {
                        Text(viewModel.transcribedText.isEmpty ? "The question will appear here..." : viewModel.transcribedText)
                            .padding()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .liquidGlass()
                    }
                    .padding(.horizontal)
                    
                    // Generated Answer
                    if !viewModel.generatedAnswer.isEmpty {
                        Text(viewModel.transcribedText.isEmpty ? "The question will appear here..." : viewModel.transcribedText)
                            .padding()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ScrollView {
                            Text(viewModel.generatedAnswer)
                                .bold()
                                .padding()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .liquidGlass()
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Error Message
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .liquidGlass()
                }
                
                Spacer()
                
                // Control Button
                Button(action: {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
                }) {
                    HStack {
                        Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        Text(viewModel.isRecording ? "Stop" : "Start")
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
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
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
            }
            .padding(.top, 100)
         
            .fullScreenCover(isPresented: $viewModel.isRecording) {
                RecordingView<InterviewAceViewModel>(viewModel: viewModel)
            }
        }
    }
}

struct InterviewAceView_Previews: PreviewProvider {
    static var previews: some View {
        InterviewAceView()
    }
}
