import Foundation
import UIKit

enum MessageContent {
    case text(String)
    case image(UIImage)
    
    var textContent: String? {
        switch self {
        case .text(let text): return text
        case .image(_): return nil
        }
    }
    
    var imageContent: UIImage? {
        switch self {
        case .text(_): return nil
        case .image(let image): return image
        }
    }
}

struct Message: Identifiable {
    let id = UUID()
    let content: MessageContent
    let isUser: Bool
    let timestamp: Date
    
    init(content: MessageContent, isUser: Bool, timestamp: Date = Date()) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}
