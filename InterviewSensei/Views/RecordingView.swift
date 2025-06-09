import SwiftUI

struct RecordingView<T: RecordingProtocol>: View where T: ObservableObject {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: T
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "1A1E29"),
                    Color(hex: "1A1E29"),

                    Color(hex: "3B4B74"),
                    
                    Color(hex: "638AD6")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all) // Ensures the gradient fills the entire screen
            
            
            VStack {
                Spacer()
                
                Text("Listening...")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 50)

                WaveAnimationView(audioVolume: viewModel.audioVolume)
                    .frame(height: 100) // Adjust height as needed
                    .padding(.horizontal)

                Spacer()

                HStack(spacing: 40) {
                 
                    Button(action: {
                        // Cancel recording action - ensure stopRecording is called
                        viewModel.stopRecording()
                        // Additional logic to discard recorded audio if necessary
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .padding(20)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView(viewModel: InterviewAceViewModel()) // Keep InterviewAceViewModel for preview
    }
} 
struct GradientBackgroundView: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "1a1a2e"), // Top color: Very dark desaturated blue (almost black)
                Color(hex: "16213e"), // Middle color: Slightly lighter, more blue-ish dark tone
                Color(hex: "0f3460")  // Bottom color: Deeper, richer blue
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all) // Ensures the gradient fills the entire screen
    }
}

// MARK: - Color Extension for Hex Initialization (Crucial for SwiftUI)
// This extension allows you to create a Color object directly from a hex string.
// You'll need to include this in your project if you don't have it already.
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0) // Default to clear if hex is invalid
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
