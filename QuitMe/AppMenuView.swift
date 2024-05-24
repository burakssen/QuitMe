//
//  AppMenu.swift
//  QuitMe
//
//  Created by burak şen on 24.05.24.
//

import Cocoa
import SwiftUI

struct AppMenuView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @State var selectAll: Bool = false
    @State var settingsPopover: Bool = false
    
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
                ForEach(appDelegate.menuItems.indices, id: \.self){ index in
                    HStack {
                        Toggle(isOn: appDelegate.MenuItemBinding(for: appDelegate.menuItems[index])){
                            HStack{
                                if (appDelegate.menuItems[index].item.icon != nil) {
                                    Image(nsImage: appDelegate.menuItems[index].item.icon!)
                                        .scaleEffect(CGSize(width: 0.7, height: 0.7))
                                }
                                Text(appDelegate.menuItems[index].item.localizedName ?? "Unknown")
                            }
                        }.toggleStyle(.checkbox)
                        Spacer()
                        /*Button(action: {}, label: {Image(systemName: "minus.circle.fill")})
                            .buttonStyle(.borderless)
                            .imageScale(.large)*/
                        Button(action: {
                            appDelegate.menuItems[index].item.terminate()
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
}
