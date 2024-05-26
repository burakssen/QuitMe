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
    @State var selectAll: Bool = false
    @State var settingsPopover: Bool = false
    
    @Query(sort: \IgnoredItem.id) var ignoredItems: [IgnoredItem]
    @Environment(\.modelContext) var modelContext
    
    var filteredMenuItems: [MenuItem] {
        appDelegate.menuItems.filter { menuItem in
            !ignoredItems.contains(where: { $0.id == menuItem.id })
        }
    }
    
    var body: some View {
        VStack (alignment: .leading){
            HStack {
                Button(action: self.TerminateSelected, label: {
                    Text("Quit Selected")
                        .padding(.vertical, 3)
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                Spacer()
                Button(action: {
                    self.settingsPopover.toggle()
                }, label: {
                    Image(systemName: "gear")
                })
                .buttonStyle(.borderless)
                .imageScale(.large)
                .popover(isPresented: self.$settingsPopover, arrowEdge: .trailing){
                    SettingsView()
                        .environmentObject(appDelegate)
                        .modelContainer(for: IgnoredItem.self)
                        .modelContext(self.modelContext)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top)
            HStack {
                Toggle(isOn: self.selectAllBinding()){}
                    .onChange(of: selectAll){
                        for index in appDelegate.menuItems.indices {
                            appDelegate.checkedItems[appDelegate.menuItems[index]] = selectAll;
                        }
                    }
                Text("Select All")
            }
            VStack(alignment: .leading, spacing: 2) {
                ForEach(filteredMenuItems) { menuItem in
                    HStack {
                        Toggle(isOn: appDelegate.MenuItemBinding(for: menuItem)) {
                            HStack {
                                if (menuItem.item.icon != nil) {
                                    Image(nsImage: menuItem.item.icon!)
                                        .scaleEffect(CGSize(width: 0.7, height: 0.7))
                                }
                                Text(menuItem.item.localizedName ?? "Unknown")
                            }
                        }.toggleStyle(.checkbox)
                        Spacer()
                        Button(action: {
                            let menuItemBinding = appDelegate.MenuItemBinding(for: menuItem)
                            if menuItemBinding.wrappedValue == true {
                                menuItemBinding.wrappedValue.toggle()
                            }
                            let ignoredItem = IgnoredItem(id: menuItem.id)
                            self.modelContext.insert(ignoredItem)
                        }, label: {Image(systemName: "plus.circle.fill")})
                            .buttonStyle(.borderless)
                            .imageScale(.large)
                        Button(action: {
                            menuItem.item.terminate()
                        }, label: {Image(systemName: "bolt.horizontal.circle.fill")})
                        .buttonStyle(.borderless)
                        .imageScale(.large)
                    }
                }
            }.padding(.bottom)
            
        }
        .padding(.horizontal)
        .frame(maxWidth: 250)
    }
    
    func TerminateSelected() {
        for menuItem in appDelegate.selectedItems {
            menuItem.item.terminate()
        }
    }
    
    func selectAllBinding()  -> Binding<Bool> {
        return Binding(get: {
            self.selectAll
        }, set: {selectVal in
            self.selectAll = selectVal
        })
    }
}


#Preview {
    AppMenuView().environmentObject(AppDelegate())
        .modelContainer(for: IgnoredItem.self)
}
