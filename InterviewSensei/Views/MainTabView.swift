import SwiftUI

struct MainTabView: View {

    var body: some View {
        TabView {
            InterviewAceView()
                .tabItem {
                    Label("Interview", systemImage: "mic.fill")
                }
            InterviewWarmupView()
                .tabItem {
                    Label("Warmup", systemImage: "waveform.badge.magnifyingglass")
                }
            CVImportView(viewModel: CVImportViewModel())
                .tabItem {
                    Label("CV Import", systemImage: "doc.text.fill")
                }
            PracticeView()
                .tabItem {
                    Label("Practice", systemImage: "questionmark.circle.fill")
                }
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
            QuizStatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar")
                }
        }
        .background(Color("Light"))
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color("Light"))
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
