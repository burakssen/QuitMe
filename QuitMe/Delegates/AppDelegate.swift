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
        self.createdAt = .now
    }
}

struct MenuItem: Hashable, Identifiable {
    let id: String
    let item: NSRunningApplication
    var checked: Bool
    
    init(item: NSRunningApplication, checked: Bool = false) {
        self.id = item.bundleIdentifier ?? "Unknown"
        self.item = item
        self.checked = checked
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var menuItems: [MenuItem] = []
    @Published var checkedItems: [MenuItem: Bool] = [:]
    private var fetchTimer: Timer?
    private let center = NSWorkspace.shared.notificationCenter
    
    var selectedItems: [MenuItem] { checkedItems.filter { $0.value }.map { $0.key } }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        fetch()
        fetchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.fetch()
        }
        
        addObserver(for: NSWorkspace.didLaunchApplicationNotification, using: launchObserver)
        addObserver(for: NSWorkspace.didTerminateApplicationNotification, using: terminateObserver)
        
        setupKeyboardShortcuts()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        fetchTimer?.invalidate()
    }
    
    func fetch() {
        let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        let runningAppIds = Set(apps.compactMap { $0.bundleIdentifier })
        
        menuItems.removeAll { !runningAppIds.contains($0.id) }
        let newApps = apps.filter { app in !menuItems.contains { app.bundleIdentifier == $0.id } }
        menuItems.append(contentsOf: newApps.map { MenuItem(item: $0) })
    }
    
    func MenuItemBinding(for menuItem: MenuItem) -> Binding<Bool> {
        Binding(
            get: { self.checkedItems[menuItem] ?? false },
            set: { self.checkedItems[menuItem] = $0 }
        )
    }
    
    private func launchObserver(notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier?.contains("finder") == true,
              !menuItems.contains(where: { $0.id == app.bundleIdentifier }) else { return }
        
        menuItems.append(MenuItem(item: app))
    }
    
    private func terminateObserver(notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        menuItems.removeAll { $0.item.bundleIdentifier == app.bundleIdentifier }
    }
    
    private func addObserver(for name: NSNotification.Name, using block: @escaping (Notification) -> Void) {
        center.addObserver(forName: name, object: nil, queue: .main, using: block)
    }
    
    private func setupKeyboardShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .quitMode) { [weak self] in
            self?.handleQuit(force: false)
        }
        
        KeyboardShortcuts.onKeyDown(for: .forceQuitMode) { [weak self] in
            self?.handleQuit(force: true)
        }
    }
    
    private func handleQuit(force: Bool) {
        let items = getNonIgnoredItems()
        let actionVerb = force ? "Force Quit" : "Quit"
        let message = "\(actionVerb) Applications"
        let info = "Are you sure you want to \(actionVerb.lowercased()) the selected applications?"
        
        runWithAlert(items: items, message: message, info: info) { items in
            items.forEach { item in
                if force {
                    item.item.forceTerminate()
                } else {
                    item.item.terminate()
                }
            }
        }
    }
    
    private func getNonIgnoredItems() -> [MenuItem] {
        do {
            let container = try ModelContainer(for: IgnoredItem.self)
            let context = ModelContext(container)
            let ignoredItems = try context.fetch(FetchDescriptor<IgnoredItem>())
            return menuItems.filter { mItem in
                !ignoredItems.contains { $0.id == mItem.id }
            }
        } catch {
            print("Error fetching ignored items: \(error)")
            return []
        }
    }
    
    private func runWithAlert(items: [MenuItem], message: String, info: String, action: @escaping ([MenuItem]) -> Void) {
        guard !items.isEmpty else { return }
        
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
