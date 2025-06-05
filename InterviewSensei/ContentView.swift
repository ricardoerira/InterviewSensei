//
//  ContentView.swift
//  InterviewSensei
//
//  Created by andres on 15/05/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    let persistenceController = PersistenceController.shared
    
    var body: some View {
        MainTabView()
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
