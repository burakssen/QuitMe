//
//  AppDelegate.swift
//  QuitMe
//
//  Created by burak şen on 24.05.24.
//

import AppKit
import SwiftUI

struct MenuItem: Hashable {
    var item: NSRunningApplication
    var checked: Bool
    
    init(item: NSRunningApplication, checked: Bool) {
        self.item = item
        self.checked = checked
    }
    
    static func == (lhs: MenuItem, rhs: MenuItem) -> Bool {
        lhs.item.bundleIdentifier == rhs.item.bundleIdentifier
    }
}


final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var menuItems: [MenuItem] = []
    @Published var checkedItems: [MenuItem: Bool] = [:]
    
    public var selectedItems: [MenuItem] {
        var selected: [MenuItem] = []
        for key in self.checkedItems.keys {
            if self.checkedItems[key] == true {
                selected.append(key)
            }
        }
        return selected
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil, // always NSWorkspace
            queue: OperationQueue.main) { (notification: Notification) in
                if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                    if ((app.bundleIdentifier?.contains("finder")) != nil) {
                        self.menuItems.append(MenuItem(item:app, checked: false))
                    }
            }
        }
        
        center.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil, // always NSWorkspace
            queue: OperationQueue.main) { (notification: Notification) in
                if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                
                    self.menuItems = self.menuItems.filter { menuItems in
                        app.bundleIdentifier != menuItems.item.bundleIdentifier
                    }
            }
        }
        
        self.fetch()
    }
    
    public func fetch(){
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
                
        for app in runningApps.filter({ $0.activationPolicy == .regular }) {
            if let bident = app.bundleIdentifier {
                if bident.contains("finder") {
                    continue
                }
                let menuItem = MenuItem(item: app, checked: false)
                menuItems.append(menuItem)
                checkedItems[menuItem] = false

            }
        }
    }
    
    public func MenuItemBinding(for menuItem: MenuItem) -> Binding<Bool> {
        return Binding(
            get: { self.checkedItems[menuItem] ?? false },
            set: { self.checkedItems[menuItem] = $0 }
        )
    }
}
