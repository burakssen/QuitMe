//
//  QuitMeApp.swift
//  QuitMe
//
//  Created by burak şen on 24.05.24.
//

import SwiftUI

@main
struct QuitMeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            AppMenuView().environmentObject(appDelegate)
        } label: {
            Image(systemName: "q.circle.fill")
        }
        .menuBarExtraStyle(.window)
    }
}

