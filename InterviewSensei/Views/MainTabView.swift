import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            InterviewAceView()
                .tabItem {
                    Label("Interview", systemImage: "mic.fill")
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
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
