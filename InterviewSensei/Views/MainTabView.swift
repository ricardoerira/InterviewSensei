import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    // Define custom colors based on the provided design
    let darkBackground = Color(red: 0.05, green: 0.15, blue: 0.12) // Approximate dark teal background
    let accentColor = Color(red: 0.2, green: 0.8, blue: 0.6)     // Approximate bright teal accent
    
    var body: some View {
        ZStack { // Use ZStack to place the background color behind the TabView
            darkBackground.edgesIgnoringSafeArea(.all) // Apply the background to the entire screen area
            
            TabView(selection: $selectedTab) {
                InterviewView()
                    .tabItem {
                        Label("Interview", systemImage: "person.2.fill")
                    }
                    .tag(0)
                
                PracticeView()
                    .tabItem {
                        Label("Practice", systemImage: "mic.fill")
                    }
                    .tag(1)
                
                CVImportView(viewModel: CVImportViewModel())
                    .tabItem {
                        Label("CV", systemImage: "doc.text.fill")
                    }
                    .tag(2)
                
                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "book.fill")
                    }
                    .tag(3)
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(4)
            }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
