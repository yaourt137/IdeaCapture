//
//  IdeaCaptureApp.swift
//  IdeaCapture
//
//  想法收集应用
//

import SwiftUI
import SwiftData

@main
struct IdeaCaptureApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Idea.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            IdeaListView()
        }
        .modelContainer(sharedModelContainer)
    }
}
