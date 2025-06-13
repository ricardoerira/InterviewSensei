import SwiftUI

struct BackgroundView: View {
    let image: Image?
    let uiImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    init(image: Image? = nil, uiImage: UIImage? = nil) {
        self.image = image
        self.uiImage = uiImage
    }
    
    var body: some View {
        
        ZStack(alignment: .top) {
            if let image = image {
                backgroundIfImageSelected(image: image)
            } else if let uiImage = uiImage {
                backgroundIfImageSelected(image: Image(uiImage: uiImage))
            } else {
                backgroundIfImageSelected(image: Image("fondo2"))
            }
            
            VStack(spacing: 0) {
                // Header image with back button
                HeaderView(
                    image: Image("fondo2"),
                    onBack: nil
                )
               
                .ignoresSafeArea()
            }
        }
    }
    
    @ViewBuilder
    private func backgroundIfImageSelected(image: Image) -> some View {
        image
            .resizable()
            .scaledToFill()
            .frame(width: UIScreen.main.bounds.width)
            .ignoresSafeArea()
        
        Rectangle()
            .fill(Color.white.opacity(0.2))
        
        BlurView(style: .systemUltraThinMaterialDark)
            .ignoresSafeArea()
    }
    
    // MARK: - Preview
    struct BackgroundView_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                // Default background
                BackgroundView()
                    .previewDisplayName("Default Background")
                    .previewLayout(.sizeThatFits)
            }
        }
    }
    
    
    struct BlurView: UIViewRepresentable {
        let style: UIBlurEffect.Style
        
        func makeUIView(context: Context) -> UIVisualEffectView {
            let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
            return view
        }
        
        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
    }
    
    
    
    struct HeaderView: View {
        let image: Image?
        let onBack: (() -> Void)?
        
        var body: some View {
            ZStack(alignment: .topLeading) {
                if let image = image {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .clipped()
                        .mask(LinearGradient(gradient: Gradient(colors: [.black, .black, .clear]), startPoint: .top, endPoint: .bottom))
                       
                } else {
                    Color.gray
                        .frame(height: 250)
                }
                
                // Logo and Header at top leading
//                HStack(spacing: 10) {
//                    Spacer()
//                    VStack(spacing: 10) {
//                        
//                        Image("logo")
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            .frame(width: 70, height: 70)
//                        
//                        
//                        Image("InterviewHeader")
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            .frame(height: 70)
//                    }
//                  
//                }
//                .padding(.top, 50)
//                .padding(.horizontal)
                
                // Back button if needed
                if let onBack = onBack {
                    VStack {
                        HStack {
                            Button(action: onBack) {
                                Image(systemName: "chevron.left").bold()
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.7))
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        Spacer()
                    }.padding(.top, 50)
                } else {
                    
                }
            }
        }
    }
}

// MARK: - Header Preview
struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            
            
            // Header without image
            BackgroundView.HeaderView(image: nil, onBack: nil)
                .previewDisplayName("Header without Image")
                .previewLayout(.sizeThatFits)
            
            
        }
    }
}
