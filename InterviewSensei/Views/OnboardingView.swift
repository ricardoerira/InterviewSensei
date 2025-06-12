import SwiftUI
import AVKit

struct LiquidGlassEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(
                Color.white.opacity(0.2)
                    .blur(radius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.7),
                                .clear,
                                .white.opacity(0.2),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

extension View {
    func liquidGlass() -> some View {
        modifier(LiquidGlassEffect())
    }
}

struct OnboardingStep {
    let image: String
    let title: String
    let description: String
    let isVideoStep: Bool
}

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentStep = 0
    @StateObject private var playerViewModel = VideoPlayerViewModel()
    
    let steps = [
        OnboardingStep(
            image: "person.2.fill",
            title: "Welcome to InterviewSensei",
            description: "Your personal AI-powered interview preparation assistant",
            isVideoStep: false
        ),
        OnboardingStep(
            image: "bubble.left.and.bubble.right.fill",
            title: "Practice Interviews",
            description: "Engage in realistic mock interviews with our AI interviewer",
            isVideoStep: false
        ),
        OnboardingStep(
            image: "chart.bar.fill",
            title: "Track Progress",
            description: "Monitor your improvement with detailed feedback and analytics",
            isVideoStep: false
        ),
        OnboardingStep(
            image: "lightbulb.fill",
            title: "Smart Feedback",
            description: "Get instant, personalized feedback on your responses",
            isVideoStep: false
        )
    ]
    
    var body: some View {
        ZStack {
            // Video Background
            if let player = playerViewModel.player {
                VideoPlayer(player: player)
                    .scaleEffect(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                .clear,
                                .black.opacity(0.7),
                                .black.opacity(1),
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                .clear,
                                .clear,
                                .clear,
                                Color("Blue").opacity(0.3),
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            }
            
            // Content
            VStack(spacing: 20) {
                Spacer()
                TabView(selection: $currentStep) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        VStack(spacing: 10) {
                            Image("logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 70, height: 70)
                                .padding()
                            
                            Text(steps[index].title)
                                .font(.title)
                                .bold()
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .padding(.horizontal, 50)
                                .fixedSize(horizontal: false, vertical: true)

//                                .liquidGlass()
                            
                            Text(steps[index].description)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .fixedSize(horizontal: false, vertical: true)

                                .padding()
//                                .liquidGlass()
                        }
                        .tag(index)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        .animation(.easeInOut, value: currentStep)
                    }
                }
                .padding(.top, 400)
                .ignoresSafeArea()
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: currentStep) { newStep in
                    playerViewModel.setupPlayer(for: newStep)
                }
                

                // Navigation Buttons
                HStack {
                    if currentStep > 0 {
                        
                        
                        Button("Previous") {
                            currentStep -= 1
                        }
                        .buttonStyle(GlassButtonStyle())
                        .padding()
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    Button(currentStep < steps.count - 1 ? "    Next    " : "Get Started") {
                        if currentStep < steps.count - 1 {
                            withAnimation {
                                currentStep += 1
                            }
                        } else {
                            hasCompletedOnboarding = true
                        }
                    }   .buttonStyle(GlassButtonStyle())
                        .padding()
                        .transition(.scale.combined(with: .opacity))
//                    Button(action: {
//                        if currentStep < steps.count - 1 {
//                            withAnimation {
//                                currentStep += 1
//                            }
//                        } else {
//                            hasCompletedOnboarding = true
//                        }
//                    }) {
//                        Text(currentStep < steps.count - 1 ? "Next" : "Get Started")
//                            .font(.headline)
//                            .foregroundColor(.white)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .liquidGlass()
//                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            playerViewModel.setupPlayer(for: currentStep)
        }
    }
}

struct VideoPlayerView: View {
    @StateObject private var playerViewModel = VideoPlayerViewModel()
    
    var body: some View {
        ZStack {
            if let player = playerViewModel.player {
                VideoPlayer(player: player)
                    .scaleEffect(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                .black.opacity(0.7),
                                .black.opacity(0.8),
                                .black.opacity(1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .tint(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            playerViewModel.setupPlayer(for: 0)
        }
    }
}

class VideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer?
    private var currentStep: Int = 0
    
    func setupPlayer(for step: Int) {
        // Clean up previous player
        player?.pause()
        player = nil
        
        // Get video name based on step
        let videoName: String
        switch step {
        case 0:
            videoName = "1"
        case 1:
            videoName = "2"
        case 2:
            videoName = "3"
        case 3:
            videoName = "4"
        default:
            videoName = "1"
        }
        
        if let videoURL = Bundle.main.url(forResource: videoName, withExtension: "mp4") {
            let player = AVPlayer(url: videoURL)
            player.actionAtItemEnd = .none
            player.isMuted = true
            
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                object: player.currentItem,
                                                queue: .main) { [weak player] _ in
                player?.seek(to: .zero)
                player?.play()
            }
            self.player = player
            self.currentStep = step
            player.play()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

#Preview {
    OnboardingView()
}
