//
//  PopoverView.swift
//  QuitMe
//
//  Created by burak şen on 27.05.24.
//

import SwiftUI

struct PopoverView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 1) {
            PopoverButton(
                icon: "xmark.circle.fill",
                title: "Quit",
                action: {
                    NSApplication.shared.terminate(nil)
                    dismiss()
                }
            )
            
            PopoverButton(
                icon: "gearshape",
                title: "Preferences",
                action: {
                    openWindow(id: "preferences")
                    dismiss()
                }
            )
            
            PopoverButton(
                icon: "questionmark.circle",
                title: "Help",
                action: {
                    openWindow(id: "help")
                    dismiss()
                }
            )
        }
        .padding(.vertical, 1)
        .frame(width: 250)
        .background(Color(.windowBackgroundColor))
    }
}

struct PopoverButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(isHovered ? Color.secondary.opacity(0.2) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct PopoverView_Previews: PreviewProvider {
    static var previews: some View {
        PopoverView()
    }
}
