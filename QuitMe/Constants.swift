//
//  Constants.swift
//  QuitMe
//
//  Created by burak şen on 27.05.24.
//

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let quitMode = Self("quitMode", default: .init(.q, modifiers: [.option,.control]))
    static let forceQuitMode = Self("forceQuitMode", default: .init(.q, modifiers: [.option, .control, .shift]))
}
