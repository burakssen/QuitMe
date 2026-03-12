//
//  AppDelegate.swift
//  QuitMe
//
//  Created by burak şen on 24.05.24.
//

import AppKit
import CoreGraphics
import SwiftUI
import SwiftData
import KeyboardShortcuts

struct MenuItem: Hashable, Identifiable {
    var id: pid_t { processIdentifier }
    let bundleId: String
    let processIdentifier: pid_t
    let item: NSRunningApplication
    
    init(item: NSRunningApplication) {
        self.bundleId = item.bundleIdentifier ?? UUID().uuidString
        self.processIdentifier = item.processIdentifier
        self.item = item
    }
    
    static func == (lhs: MenuItem, rhs: MenuItem) -> Bool {
        lhs.processIdentifier == rhs.processIdentifier
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(processIdentifier)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var menuItems: [MenuItem] = []
    @Published var checkedItems: [MenuItem: Bool] = [:]
    @Published private(set) var windowOwnerProcessIdentifiers: Set<pid_t> = []
    private var fetchTimer: Timer?
    private let center = NSWorkspace.shared.notificationCenter
    
    var container: ModelContainer?
    
    var selectedItems: [MenuItem] { checkedItems.filter { $0.value }.map { $0.key } }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        fetch()
        fetchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetch()
            }
        }
        
        addObserver(for: NSWorkspace.didLaunchApplicationNotification, selector: #selector(launchObserver(notification:)))
        addObserver(for: NSWorkspace.didTerminateApplicationNotification, selector: #selector(terminateObserver(notification:)))
        
        setupKeyboardShortcuts()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        fetchTimer?.invalidate()
    }
    
    func fetch() {
        let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        let runningPids = Set(apps.map { $0.processIdentifier })
        
        menuItems.removeAll { !runningPids.contains($0.processIdentifier) }
        let newApps = apps.filter { app in !menuItems.contains { app.processIdentifier == $0.processIdentifier } }
        menuItems.append(contentsOf: newApps.map { MenuItem(item: $0) })
        updateWindowOwnerProcessIdentifiers()
    }
    
    func MenuItemBinding(for menuItem: MenuItem) -> Binding<Bool> {
        Binding(
            get: { self.checkedItems[menuItem] ?? false },
            set: { self.checkedItems[menuItem] = $0 }
        )
    }
    
    @objc
    private func launchObserver(notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.activationPolicy == .regular,
              !menuItems.contains(where: { $0.processIdentifier == app.processIdentifier }) else { return }
        
        menuItems.append(MenuItem(item: app))
        updateWindowOwnerProcessIdentifiers()
    }
    
    @objc
    private func terminateObserver(notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        menuItems.removeAll { $0.processIdentifier == app.processIdentifier }
        checkedItems.removeValue(forKey: MenuItem(item: app))
        updateWindowOwnerProcessIdentifiers()
    }
    
    private func addObserver(for name: NSNotification.Name, selector: Selector) {
        center.addObserver(self, selector: selector, name: name, object: nil)
    }
    
    private func setupKeyboardShortcuts() {
        KeyboardShortcuts.onKeyDown(for: .quitMode) { [weak self] in
            Task { @MainActor in
                self?.handleQuit(force: false)
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .forceQuitMode) { [weak self] in
            Task { @MainActor in
                self?.handleQuit(force: true)
            }
        }
    }
    
    func handleQuit(force: Bool, items: [MenuItem]? = nil) {
        let itemsToQuit = items ?? getNonIgnoredItems()
        guard !itemsToQuit.isEmpty else { return }
        
        let actionVerb = force ? "Force Quit" : "Quit"
        let message = "\(actionVerb) Applications"
        let info = "Are you sure you want to \(actionVerb.lowercased()) the selected applications?"
        
        runWithAlert(items: itemsToQuit, message: message, info: info) { items in
            items.forEach { item in
                if force {
                    item.item.forceTerminate()
                } else {
                    item.item.terminate()
                }
            }
        }
    }

    func hasOpenWindow(for menuItem: MenuItem) -> Bool {
        windowOwnerProcessIdentifiers.contains(menuItem.processIdentifier)
    }

    func itemsWithoutOpenWindows(from items: [MenuItem]? = nil) -> [MenuItem] {
        let sourceItems = items ?? getNonIgnoredItems()
        return sourceItems.filter { !hasOpenWindow(for: $0) }
    }
    
    private func getNonIgnoredItems() -> [MenuItem] {
        guard let container = container else { return [] }
        let context = container.mainContext
        do {
            let ignoredItems = try context.fetch(FetchDescriptor<IgnoredItem>())
            return menuItems.filter { mItem in
                !ignoredItems.contains { $0.id == mItem.bundleId }
            }
        } catch {
            print("Error fetching ignored items: \(error)")
            return []
        }
    }

    private func updateWindowOwnerProcessIdentifiers() {
        guard
            let rawWindowInfo = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID)
                as? [[String: Any]]
        else {
            windowOwnerProcessIdentifiers = []
            return
        }

        windowOwnerProcessIdentifiers = Set(
            rawWindowInfo.compactMap { windowInfo in
                guard
                    let ownerPID = windowInfo[kCGWindowOwnerPID as String] as? pid_t,
                    let layer = windowInfo[kCGWindowLayer as String] as? Int,
                    layer == 0,
                    let alpha = windowInfo[kCGWindowAlpha as String] as? Double,
                    alpha > 0,
                    let boundsDictionary = windowInfo[kCGWindowBounds as String] as? NSDictionary,
                    let bounds = CGRect(dictionaryRepresentation: boundsDictionary),
                    !bounds.isEmpty
                else {
                    return nil
                }

                return ownerPID
            }
        )
    }
    
    private func runWithAlert(items: [MenuItem], message: String, info: String, action: @escaping ([MenuItem]) -> Void) {
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
