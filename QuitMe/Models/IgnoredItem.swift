//
//  IgnoredItem.swift
//  QuitMe
//
//  Created by burak şen on 24.05.24.
//

import Foundation
import SwiftData

@Model
class IgnoredItem {
    @Attribute(.unique) var id: String
    var createdAt: Date
    
    init(id: String) {
        self.id = id
        self.createdAt = .now
    }
}
