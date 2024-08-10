//
//  AppMenu.swift
//  QuitMe
//
//  Created by burak şen on 24.05.24.
//

import Cocoa
import SwiftUI
import SwiftData

struct AppMenuView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @State private var selectAll = false
    @State private var showSettings = false
    
    @Query(sort: \IgnoredItem.id) private var ignoredItems: [IgnoredItem]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow

    private var filteredMenuItems: [MenuItem] {
        appDelegate.menuItems.filter { menuItem in
            !ignoredItems.contains { $0.id == menuItem.id }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
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
            settingsButton
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
            .frame(maxWidth: .infinity) // Make the button fill the available width
            .background(Color.red)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
        }
        .buttonStyle(PlainButtonStyle())
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var settingsButton: some View {
        Button(action: { showSettings.toggle() }) {
            Image(systemName: "gear")
                .imageScale(.large)
                .foregroundColor(.secondary)
                .frame(width: 32, height: 32)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $showSettings, arrowEdge: .bottom) {
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
            Toggle("", isOn: $selectAll)
                .toggleStyle(
                    SwitchToggleStyle(tint: .accentColor)
                )
                .scaleEffect(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onChange(of: selectAll) { _, newValue in
            for menuItem in appDelegate.menuItems {
                if ignoredItems.contains(where: { $0.id == menuItem.id }) {
                    appDelegate.checkedItems[menuItem] = false
                } else {
                    appDelegate.checkedItems[menuItem] = newValue
                }
            }
        }
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
        for menuItem in appDelegate.selectedItems {
            menuItem.item.terminate()
        }
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
        let menuItemBinding = appDelegate.MenuItemBinding(for: menuItem)
        if menuItemBinding.wrappedValue {
            menuItemBinding.wrappedValue.toggle()
        }
        let ignoredItem = IgnoredItem(id: menuItem.id)
        modelContext.insert(ignoredItem)
    }
}

#Preview {
    AppMenuView()
        .environmentObject(AppDelegate())
        .modelContainer(for: IgnoredItem.self)
}
