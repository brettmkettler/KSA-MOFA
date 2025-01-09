import Foundation

class VectorDBService {
    private let openAIService = OpenAIService()
    private let documentProcessor = DocumentProcessingService()
    private var processedDocuments: [ProcessedDocument] = []
    private var documentEmbeddings: [String: [Float]] = [:] // sourceFile -> embedding
    
    // Function to generate embeddings using OpenAI
    func generateEmbedding(for text: String) async throws -> [Float] {
        let endpoint = "https://api.openai.com/v1/embeddings"
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(openAIService.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "text-embedding-ada-002",
            "input": text
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(EmbeddingResponse.self, from: data)
        
        return response.data.first?.embedding ?? []
    }
    
    // Function to process and embed documents
    func processAndEmbedDocument(at url: URL) async throws {
        let processedDoc = try documentProcessor.processDocument(at: url)
        processedDocuments.append(processedDoc)
        
        // Generate embedding for the document content
        let embedding = try await generateEmbedding(for: processedDoc.content)
        documentEmbeddings[processedDoc.sourceFile] = embedding
        
        print("Processed and embedded document: \(processedDoc.sourceFile)")
    }
    
    // Function to process multiple documents
    func processDocuments(urls: [URL]) async {
        for url in urls {
            do {
                try await processAndEmbedDocument(at: url)
            } catch {
                print("Error processing document \(url.lastPathComponent): \(error)")
            }
        }
    }
    
    // Function to find similar documents
    func findSimilarDocuments(for query: String, limit: Int = 3) async throws -> [ProcessedDocument] {
        let queryEmbedding = try await generateEmbedding(for: query)
        
        let documentsWithScores = documentEmbeddings.map { (sourceFile, embedding) -> (String, Float) in
            let similarity = cosineSimilarity(queryEmbedding, embedding)
            return (sourceFile, similarity)
        }
        
        let sortedDocuments = documentsWithScores.sorted { $0.1 > $1.1 }
        let topDocuments = sortedDocuments.prefix(limit)
        
        return topDocuments.compactMap { sourceFile, _ in
            processedDocuments.first { $0.sourceFile == sourceFile }
        }
    }
    
    // Helper function to calculate cosine similarity
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let normA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let normB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        return dotProduct / (normA * normB)
    }
}

struct EmbeddingResponse: Codable {
    let data: [EmbeddingData]
}

struct EmbeddingData: Codable {
    let embedding: [Float]
}
