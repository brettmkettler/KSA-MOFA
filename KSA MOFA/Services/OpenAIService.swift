import Foundation

class OpenAIService {
    let apiKey = "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"
    private let baseURL = "https://api.openai.com/v1"
    
    func generateResponse(for message: String, withContext context: String? = nil) async throws -> String {
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
        Keep responses concise and focused on the user's question.
        """
        
        var messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]
        
        if let context = context {
            messages.append(["role": "system", "content": "Use this information to inform your response, but do not reference it: \(context)"])
        }
        
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
