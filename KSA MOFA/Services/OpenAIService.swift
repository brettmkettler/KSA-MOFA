import Foundation
import UIKit

class OpenAIService {
    let apiKey = "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"
    private let baseURL = "https://api.openai.com/v1"
    private let maxHistoryMessages = 10
    
    func generateResponse(for message: String, withContext context: String? = nil, previousMessages: [Message] = []) async throws -> String {
        let endpoint = "\(baseURL)/chat/completions"
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemPrompt = """
        You are a helpful assistant for the KSA MOFA (Ministry of Foreign Affairs). \
        Provide clear, direct answers about MOFA services and information. \
        Do not mention or reference any source documents in your responses. \
        Simply provide the information as if you inherently know it. \
        Keep responses concise and focused on the user's question. \
        Maintain context from the conversation history to provide relevant responses.
        """
        
        var messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]
        
        if let context = context {
            messages.append(["role": "system", "content": "Use this information to inform your response, but do not reference it: \(context)"])
        }
        
        // Add conversation history (last 10 messages)
        let recentMessages = previousMessages.suffix(maxHistoryMessages)
        for historyMessage in recentMessages {
            if let textContent = historyMessage.content.textContent {
                messages.append([
                    "role": historyMessage.isUser ? "user" : "assistant",
                    "content": textContent
                ])
            }
        }
        
        // Add the current message
        messages.append(["role": "user", "content": message])
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        return response.choices.first?.message.content ?? "I apologize, but I couldn't generate a response."
    }
    
    func analyzeImage(_ image: UIImage, withPrompt prompt: String = """
        As a MOFA assistant, analyze this image and describe:
        1. Any official documents or forms visible
        2. Relevant passport or visa information
        3. Any embassy or consulate buildings
        4. Official seals or stamps
        5. Any text in Arabic or English
        Provide a clear, professional description focusing on aspects relevant to MOFA services.
        """) async throws -> String {
        let endpoint = "\(baseURL)/chat/completions"
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        let base64Image = imageData.base64EncodedString()
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let content: [[String: Any]] = [
            ["type": "text", "text": prompt],
            ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "user", "content": content]
            ],
            "max_tokens": 300
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        return response.choices.first?.message.content ?? "I couldn't analyze the image."
    }
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: ChatMessage
}

struct ChatMessage: Codable {
    let content: String
}

// Removed the Message and MessageContent structs as they were not being used in the provided code.
