//
//  Item.swift
//  PurposeReminder
//
//  Created by 박문수 on 3/3/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
