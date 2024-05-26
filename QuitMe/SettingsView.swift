//
//  SettingsView.swift
//  QuitMe
//
//  Created by burak şen on 25.05.24.
//

import SwiftUI
import SwiftData
import LaunchAtLogin


struct SettingsView: View {
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
            Button(action: {
                NSApplication.shared.terminate(nil)
            }, label: {
                Image(systemName: "xmark.circle.fill")
                Text("Quit")
            })
            .controlSize(.large)
            .buttonStyle(.borderless)
            .buttonBorderShape(.buttonBorder)
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
            Divider()
                .frame(maxWidth: .infinity)
            LaunchAtLogin.Toggle {
                Text("Launch At Login 🚀")
            }
        }.padding(.all)
            .frame(width: 200)
    }
}

#Preview {
    SettingsView().modelContainer(for: IgnoredItem.self)
}
