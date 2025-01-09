//
//  Item.swift
//  KSA MOFA
//
//  Created by Brett Kettler on 1/8/25.
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
