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
        let iItems = appDelegate.menuItems.filter { menuItem in
            ignoredItems.contains(where: { $0.id == menuItem.id })
        }
        
        return iItems
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Preferences")
            Divider()
            Text("Ignored Apps")
            ForEach(ignoredItemList){ ignoredItem in
                HStack{
                    if ((ignoredItem.item.icon) != nil){
                        Image(nsImage: ignoredItem.item.icon!)
                    }
                    Text(ignoredItem.item.localizedName ?? "Unknown")
                    Spacer()
                    Button(action: {
                        do {
                            let itemToDelete = ignoredItems.first(where: { $0.id == ignoredItem.id })
                            if let itemToDelete = itemToDelete {
                                modelContext.delete(itemToDelete)
                                try modelContext.save()
                            }
                        } catch {
                            print("Error deleting ignored item: \(error.localizedDescription)")
                        }
                    }, label: {
                        Text(Image(systemName: "minus.circle.fill"))
                    })
                    .buttonStyle(.borderless)
                    .imageScale(.large)
                }
                
            }
            .frame(maxWidth: .infinity)
            Divider()
            Text("Shortcuts")
            Form {
                KeyboardShortcuts.Recorder("Quit All", name: .quitMode)
                KeyboardShortcuts.Recorder("Force Quit All", name: .forceQuitMode)
            }.frame(alignment: .leading)
            Divider()
            LaunchAtLogin.Toggle {
                Text("Launch At Login 🚀")
            }
        }.padding(.all)
    }
}

#Preview {
    PreferencesView().modelContainer(for: IgnoredItem.self)
}
