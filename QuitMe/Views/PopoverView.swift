//
//  PopoverView.swift
//  QuitMe
//
//  Created by burak şen on 27.05.24.
//

import SwiftUI

struct PopoverView: View {
    
    @Environment(\.openWindow) private var openWindow
    @State var isHover:[Bool] = [false, false, false]
    private var buttons: [(String, String, () -> ())] {
        [
            ("xmark.circle.fill", "Quit", {}),
            ("gearshape", "Preferences", {self.openWindow(id: "preferences")}),
            ("questionmark.circle", "Help", {self.openWindow(id: "help")})
        ]
    }
    
    var body: some View {
        List([0, 1, 2], id:\.self) { row in
            HStack{
                Button {
                    buttons[row].2()
                } label: {
                    Image(systemName: buttons[row].0)
                        .scaledToFill()
                    Text(buttons[row].1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.all, 5)
                }
                .padding(.horizontal, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .buttonStyle(.bordered)
                .onHover(perform: { hovering in
                    isHover[row] = hovering
                })
            }
            .listRowSeparator(.hidden)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PopoverView()
}
