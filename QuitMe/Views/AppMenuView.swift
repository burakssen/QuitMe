//
//  AppMenuView.swift
//  QuitMe
//
//  Created by burak şen on 24.05.24.
//

import Cocoa
import SwiftUI
import SwiftData

struct AppMenuView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @State private var showPreferences = false
    
    @Query(sort: \IgnoredItem.id) private var ignoredItems: [IgnoredItem]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow

    private var filteredMenuItems: [MenuItem] {
        appDelegate.menuItems.filter { menuItem in
            !ignoredItems.contains { $0.id == menuItem.bundleId }
        }
    }

    private var windowlessItems: [MenuItem] {
        appDelegate.itemsWithoutOpenWindows(from: filteredMenuItems)
    }
    
    private var allSelected: Binding<Bool> {
        Binding {
            !filteredMenuItems.isEmpty && filteredMenuItems.allSatisfy { appDelegate.checkedItems[$0] == true }
        } set: { newValue in
            for menuItem in filteredMenuItems {
                appDelegate.checkedItems[menuItem] = newValue
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            quitWindowlessButton
            selectAllToggle
            menuItemsList
        }
        .padding()
        .frame(width: 320)
        .background(Color(.windowBackgroundColor))
    }
    
    private var headerView: some View {
        HStack {
            quitSelectedButton
            Spacer()
            preferencesButton
        }
    }

    private var quitSelectedButton: some View {
        Button(action: terminateSelected) {
            HStack {
                Image(systemName: "power")
                    .font(.system(size: 14, weight: .semibold))
                Text("Quit Selected")
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
        }
        .buttonStyle(PlainButtonStyle())
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private var quitWindowlessButton: some View {
        Button(action: terminateWindowless) {
            HStack {
                Image(systemName: "rectangle.stack.badge.minus")
                    .font(.system(size: 13, weight: .semibold))
                Text(windowlessButtonTitle)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.secondary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(windowlessItems.isEmpty)
        .opacity(windowlessItems.isEmpty ? 0.5 : 1.0)
    }
    
    private var preferencesButton: some View {
        Button(action: { showPreferences.toggle() }) {
            Image(systemName: "gear")
                .imageScale(.large)
                .foregroundColor(.secondary)
                .frame(width: 32, height: 32)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $showPreferences, arrowEdge: .bottom) {
            PopoverView()
                .frame(width: 250)
                .padding(0)
        }
    }
    
    private var selectAllToggle: some View {
        HStack {
            Text("Select All Applications")
                .font(.system(size: 14, weight: .medium))
                Spacer()
            Toggle("", isOn: allSelected)
                .toggleStyle(
                    SwitchToggleStyle(tint: .accentColor)
                )
                .scaleEffect(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var menuItemsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(filteredMenuItems) { menuItem in
                    MenuItemRow(menuItem: menuItem)
                }
            }
        }
    }
    
    private func terminateSelected() {
        let items = appDelegate.selectedItems
        guard !items.isEmpty else { return }
        
        appDelegate.handleQuit(force: false, items: items)
    }

    private var windowlessButtonTitle: String {
        if windowlessItems.isEmpty {
            return "No Apps Without Windows"
        }

        return "Quit Apps Without Windows (\(windowlessItems.count))"
    }

    private func terminateWindowless() {
        guard !windowlessItems.isEmpty else { return }
        appDelegate.handleQuit(force: false, items: windowlessItems)
    }
}

struct MenuItemRow: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @Environment(\.modelContext) private var modelContext
    let menuItem: MenuItem
    
    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: appDelegate.MenuItemBinding(for: menuItem))
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            
            if let icon = menuItem.item.icon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "app")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.secondary)
            }
            
            Text(menuItem.item.localizedName ?? "Unknown")
                .lineLimit(1)
                .truncationMode(.tail)
            
            if !appDelegate.hasOpenWindow(for: menuItem) {
                Text("No windows")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }

            Spacer()
            
            HStack(spacing: 8) {
                Button(action: ignoreItem) {
                    Image(systemName: "eye.slash")
                        .foregroundColor(.blue)
                        .frame(width: 30, height: 30)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .help("Ignore this app")
                
                Button(action: { menuItem.item.terminate() }) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.red)
                        .frame(width: 30, height: 30)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .help("Terminate this app")
            }
        }
        .padding(.vertical, 4)
    }
    
    private func ignoreItem() {
        appDelegate.checkedItems.removeValue(forKey: menuItem)
        let ignoredItem = IgnoredItem(id: menuItem.bundleId)
        modelContext.insert(ignoredItem)
        try? modelContext.save()
    }
}

#Preview {
    AppMenuView()
        .environmentObject(AppDelegate())
        .modelContainer(for: IgnoredItem.self)
}
