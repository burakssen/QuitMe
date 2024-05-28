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
    
    var body: some Scene {
        MenuBarExtra {
            AppMenuView()
                .environmentObject(appDelegate)
                .modelContainer(for: IgnoredItem.self)
        } label: {
            Image(systemName: "q.square")
        }
        .menuBarExtraStyle(.window)
        .modelContainer(for: IgnoredItem.self)
        
        WindowGroup(id: "preferences") {
            PreferencesView()
                .environmentObject(appDelegate)
                .modelContainer(for: IgnoredItem.self)
                .frame(maxWidth: 300)
        }.windowResizability(.contentSize)
    }
}
