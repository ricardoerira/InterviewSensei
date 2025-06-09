import SwiftUI

struct InterviewAceView: View {
    @StateObject private var viewModel = InterviewAceViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Interview Ace")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Status Indicators
            HStack(spacing: 20) {
                VStack {
                    Circle()
                        .fill(viewModel.isRecording ? Color.clear : Color.gray)
                        .frame(width: 20, height: 20)
                    Text("Listening")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                StatusIndicator(
                    title: "Processing",
                    isActive: viewModel.isProcessing,
                    color: .orange
                )
            }
            .padding(.horizontal)
            
            // Transcribed Text
            ScrollView {
                Text(viewModel.transcribedText.isEmpty ? "Your speech will appear here..." : viewModel.transcribedText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .frame(height: 150)
            
            // Generated Answer
            if !viewModel.generatedAnswer.isEmpty {
                ScrollView {
                    Text(viewModel.generatedAnswer)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .frame(height: 200)
            }
            
            // Error Message
            if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
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
                .background(viewModel.isRecording ? Color.red : Color.blue)
                .cornerRadius(15)
            }
            .padding(.horizontal)
        }
        .padding()
        .fullScreenCover(isPresented: $viewModel.isRecording) {
            RecordingView<InterviewAceViewModel>(viewModel: viewModel)
        }
    }
}

// MARK: - Supporting Views
struct StatusIndicator: View {
    let title: String
    let isActive: Bool
    let color: Color
    
    var body: some View {
        VStack {
            Circle()
                .fill(isActive ? color : Color.gray)
                .frame(width: 20, height: 20)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct InterviewAceView_Previews: PreviewProvider {
    static var previews: some View {
        InterviewAceView()
    }
} 