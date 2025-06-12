//
//  ContentView.swift
//  InterviewSensei
//
//  Created by andres on 15/05/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    let persistenceController = PersistenceController.shared
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else {
        MainTabView()
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
