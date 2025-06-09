import SwiftUI

struct RecordingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 4, height: 20)
                    .scaleEffect(y: isAnimating ? 1.0 : 0.3, anchor: .center)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(0.2 * Double(index)),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct RecordingIndicator_Previews: PreviewProvider {
    static var previews: some View {
        RecordingIndicator()
            .previewLayout(.sizeThatFits)
            .padding()
    }
} 