//
//  PreferencesView.swift
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Preferences")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Ignored Apps")
                .font(.headline)
            ScrollView {
                IgnoredAppsSection(ignoredItems: ignoredItems, modelContext: modelContext)
            }
            .frame(maxHeight: 500)
            
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
    let ignoredItems: [IgnoredItem]
    let modelContext: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(ignoredItems) { ignoredItem in
                IgnoredItemRow(ignoredItem: ignoredItem, modelContext: modelContext)
            }
            
            if ignoredItems.isEmpty {
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
    let ignoredItem: IgnoredItem
    let modelContext: ModelContext
    
    private var appName: String {
        if let bundleURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: ignoredItem.id) {
            return (try? bundleURL.resourceValues(forKeys: [.localizedNameKey]).localizedName) ?? ignoredItem.id
        }
        return ignoredItem.id
    }
    
    private var appIcon: NSImage? {
        if let bundleURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: ignoredItem.id) {
            return NSWorkspace.shared.icon(forFile: bundleURL.path)
        }
        return nil
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = appIcon {
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
            
            Text(appName)
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
        modelContext.delete(ignoredItem)
        try? modelContext.save()
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .environmentObject(AppDelegate())
            .modelContainer(for: IgnoredItem.self)
    }
}
