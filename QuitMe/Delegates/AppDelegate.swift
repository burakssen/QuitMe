//
//  AppDelegate.swift
//  QuitMe
//
//  Created by burak şen on 24.05.24.
//

import AppKit
import SwiftUI
import SwiftData
import KeyboardShortcuts

@Model
class IgnoredItem {
    @Attribute(.unique) var id: String
    var createdAt: Date
    
    init(id: String) {
        self.id = id
        self.createdAt = Date.now
    }
}

struct MenuItem: Hashable, Identifiable {
    public var id: String
    public var item: NSRunningApplication
    public var checked: Bool
    
    init(item: NSRunningApplication, checked: Bool) {
        self.id = item.bundleIdentifier ?? "Unknown"
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
    private var fetchTimer: Timer?
    private let center = NSWorkspace.shared.notificationCenter
    
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
        self.fetch()
        fetchTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.fetch()
        }
        
        self.addObserver(notificationName: NSWorkspace.didLaunchApplicationNotification, self.launchObserver)
        self.addObserver(notificationName: NSWorkspace.didTerminateApplicationNotification, self.terminateObserver)
        
        KeyboardShortcuts.onKeyUp(for: .quitMode) {
            let items = self.getNonIgnoredItems()
            self.runWithAlert(
                items: items,
                message: "Quit Applications",
                info: "Are you sure you want to quit the selected applications?"
            ) { items in
                for item in items {
                    item.item.terminate()
                }
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .forceQuitMode) {
            let items = self.getNonIgnoredItems()
            self.runWithAlert(
                items: items,
                message: "Force Quit Applications",
                info: "Are you sure you want to force quit the selected applications?"
            ) { items in
                for item in items {
                    item.item.forceTerminate()
                }
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        fetchTimer?.invalidate()
        fetchTimer = nil
    }
    
    public func fetch(){
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        let apps = runningApps.filter({ $0.activationPolicy == .regular })
        let runningAppIdentifiers = Set(apps.compactMap({ $0.bundleIdentifier }))
        menuItems.removeAll(where: { !runningAppIdentifiers.contains($0.id) })
        let newApps = apps.filter({ app in !menuItems.contains(where: { app.bundleIdentifier == $0.id }) })
        menuItems.append(contentsOf: newApps.map({ MenuItem(item: $0, checked: false) }))
    }
    
    public func MenuItemBinding(for menuItem: MenuItem) -> Binding<Bool> {
        return Binding(
            get: { self.checkedItems[menuItem] ?? false },
            set: { self.checkedItems[menuItem] = $0 }
        )
    }
    
    func launchObserver(notification: Notification) {
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            if ((app.bundleIdentifier?.contains("finder")) != nil && self.menuItems.filter({$0.id == app.bundleIdentifier}).count <= 0) {
                self.menuItems.append(MenuItem(item:app, checked: false))
            }
        }
    }
    
    func terminateObserver(notification: Notification){
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            self.menuItems = self.menuItems.filter { menuItems in
                app.bundleIdentifier != menuItems.item.bundleIdentifier
            }
        }
    }
    
    func addObserver(notificationName: NSNotification.Name, _ observer: @escaping (Notification) -> Void){
        self.center.addObserver(
            forName: notificationName,
            object: nil,
            queue: OperationQueue.main,
            using: observer
        )
    }
    
    private func getNonIgnoredItems() -> [MenuItem] {
        do {
            let container = try ModelContainer(for: IgnoredItem.self)
            let context = ModelContext(container)
            let fetchDescriptor = FetchDescriptor<IgnoredItem>()
            let ignoredItems = try context.fetch(fetchDescriptor) as [IgnoredItem]
            
            let items = self.menuItems.filter { mItem in
                !ignoredItems.contains { iItem in
                    iItem.id == mItem.id
                }
            }
            return items
        }
        catch {
            print("\(error)")
        }
        return []
    }
    
    private func runWithAlert(items: [MenuItem], message: String, info: String, action: ([MenuItem]) -> ()) {
        if !items.isEmpty {
            let alert = NSAlert()
            alert.messageText = message
            alert.informativeText = info
            alert.addButton(withTitle: "Quit")
            alert.addButton(withTitle: "Cancel")
                
            if alert.runModal() == .alertFirstButtonReturn {
                action(items)
            }
        }
    }
}
