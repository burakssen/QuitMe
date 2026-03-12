//
//  QuitMeApp.swift
//  QuitMe
//
//  Created by burak şen on 24.05.24.
//

import SwiftUI
import SwiftData

@main
struct QuitMeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    private let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: IgnoredItem.self)
            // Accessing appDelegate here might be tricky, but it's an adaptor.
            // We'll set it in the body to be safe, but also try to ensure it's available.
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        MenuBarExtra {
            AppMenuView()
                .environmentObject(appDelegate)
                .modelContainer(container)
        } label: {
            Image(systemName: "q.square")
        }
        .menuBarExtraStyle(.window)
        
        WindowGroup(id: "preferences") {
            PreferencesView()
                .environmentObject(appDelegate)
                .modelContainer(container)
                .frame(maxWidth: 300)
        }
        .windowResizability(.contentSize)
        .onChange(of: true, initial: true) { _, _ in
            appDelegate.container = container
        }

        WindowGroup(id: "help") {
            HelpView()
        }
        .windowResizability(.contentSize)
    }
}
