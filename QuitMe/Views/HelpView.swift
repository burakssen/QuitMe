//
//  HelpView.swift
//  QuitMe
//
//  Created by burak şen on 28.05.24.
//

import SwiftUI


struct HelpView: View {
    @Environment(\.openURL) var openURL

    var body: some View {
        HStack {
            Image("icon")
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100, alignment: .leading)
            VStack{
                Text("QuitMe v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                Button(action: {
                    openURL(URL(string: "https://github.com/burakssen/QuitMe.git")!)
                }){
                    Text("Contact Me")
                }
            }
            .padding(.all)
        }
    }
}

#Preview {
    HelpView()
}
