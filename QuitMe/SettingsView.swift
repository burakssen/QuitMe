//
//  SettingsView.swift
//  QuitMe
//
//  Created by burak şen on 25.05.24.
//

import SwiftUI

struct SettingsView: View {
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
            Text("Ignored Apps")
        }.padding(.all)
    }
}

#Preview {
    SettingsView()
}
