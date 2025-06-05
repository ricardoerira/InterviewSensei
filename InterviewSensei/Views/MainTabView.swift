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
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
