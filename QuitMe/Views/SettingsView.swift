//
//  SettingsView.swift
//  QuitMe
//
//  Created by burak şen on 25.05.24.
//

import SwiftUI
import SwiftData
import LaunchAtLogin
import KeyboardShortcuts

struct PreferencesView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @Environment(\.modelContext) var modelContext
    @Query(sort: \IgnoredItem.id) var ignoredItems: [IgnoredItem]
    
    var ignoredItemList: [MenuItem] {
        appDelegate.menuItems.filter { menuItem in
            ignoredItems.contains { $0.id == menuItem.id }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Preferences")
                .font(.title2)
                .fontWeight(.bold)
            
            // Scrollable Ignored Apps Section
            Text("Ignored Apps")
                .font(.headline)
            ScrollView {
                IgnoredAppsSection(ignoredItemList: ignoredItemList, ignoredItems: ignoredItems, modelContext: modelContext)
            }
            .frame(maxHeight: 500) // Adjust height as needed
            
            Divider()
            
            ShortcutsSection()
            
            Divider()
            
            LaunchAtLogin.Toggle {
                Text("Launch at Login")
                    .font(.subheadline)
            }
        }
        .padding()
        .frame(width: 300, height: 400)
        .background(Color(.windowBackgroundColor))
    }
}

struct IgnoredAppsSection: View {
    let ignoredItemList: [MenuItem]
    let ignoredItems: [IgnoredItem]
    let modelContext: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            
            ForEach(ignoredItemList) { ignoredItem in
                IgnoredItemRow(ignoredItem: ignoredItem, ignoredItems: ignoredItems, modelContext: modelContext)
            }
            
            if ignoredItemList.isEmpty {
                Text("No ignored apps")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
}

struct ShortcutsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shortcuts")
                .font(.headline)
            
            KeyboardShortcuts.Recorder("Quit All", name: .quitMode)
                .padding(.vertical, 4)
            
            KeyboardShortcuts.Recorder("Force Quit All", name: .forceQuitMode)
                .padding(.vertical, 4)
        }
    }
}

struct IgnoredItemRow: View {
    let ignoredItem: MenuItem
    let ignoredItems: [IgnoredItem]
    let modelContext: ModelContext
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = ignoredItem.item.icon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            } else {
                Image(systemName: "app")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.secondary)
            }
            
            Text(ignoredItem.item.localizedName ?? "Unknown")
                .font(.system(size: 14))
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
        
            Button(action: removeIgnoredItem) {
                Image(systemName: "eye")
                    .foregroundColor(.green)
                    .frame(width: 25, height: 25)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Circle())
            }
            .padding(.trailing, 15)
            .buttonStyle(PlainButtonStyle())
            .help("Remove Ignored Item")
        }
        .padding(.vertical, 4)
    }
    
    private func removeIgnoredItem() {
        do {
            if let itemToDelete = ignoredItems.first(where: { $0.id == ignoredItem.id }) {
                modelContext.delete(itemToDelete)
                try modelContext.save()
            }
        } catch {
            print("Error deleting ignored item: \(error.localizedDescription)")
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .environmentObject(AppDelegate())
            .modelContainer(for: IgnoredItem.self)
    }
}
