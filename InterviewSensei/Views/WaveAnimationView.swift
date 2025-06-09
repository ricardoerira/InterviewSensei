import SwiftUI

struct WaveAnimationView: View {
    @State private var phase: Double = 0
    var audioVolume: Float

    var body: some View {
        ZStack {
            // Background wave (slightly transparent and wider)
            Wave(amplitude: 0.1, frequency: 1.5, phase: phase)
                .stroke(Color.purple.opacity(0.4), lineWidth: 5)
                .rotationEffect(.degrees(180)) // Invert to create a layered effect
                .offset(y: 10) // Slightly offset

            // Main wave
            Wave(amplitude: 0.1, frequency: 1.5, phase: phase)
                .stroke(
                    LinearGradient(gradient: Gradient(colors: [
                        Color(hex: "1a1a2e"),
                        Color(hex: "638AD6"),
                        Color(hex: "638AD6")
                    ]), startPoint: .leading, endPoint: .trailing),
                    lineWidth: 5
                )
        }
        .onAppear {
            let animationSpeed = 2.0 - (Double(audioVolume) * 1.5) // Adjust speed based on volume (e.g., from 2.0s to 0.5s)
            withAnimation(Animation.linear(duration: max(0.2, animationSpeed)).repeatForever(autoreverses: false)) {
                phase += 1.0
            }
        }
        .frame(height: 100) // Adjust height as needed
    }
}

struct Wave: Shape {
    var amplitude: Double
    var frequency: Double
    var phase: Double

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: rect.midY))

            for x in stride(from: 0, to: rect.width, by: 1) {
                let relativeX = x / rect.width
                let angle = relativeX * Double.pi * 2.0 * frequency + phase * Double.pi * 2.0
                let sine = sin(angle)
                let offsetY = sine * (rect.height * amplitude)
                let y = rect.midY + offsetY
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
    }
}

struct WaveAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        WaveAnimationView(audioVolume: 0.5) // Pass a sample volume for preview
            .preferredColorScheme(.dark)
            .padding()
    }
} 
