//
//  InterviewSenseiApp.swift
//  InterviewSensei
//
//  Created by andres on 15/05/25.
//

import SwiftUI

@main
struct InterviewSenseiApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
