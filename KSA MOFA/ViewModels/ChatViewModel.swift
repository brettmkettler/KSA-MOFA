import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var isProcessingDocuments: Bool = false
    
    private let vectorDBService = VectorDBService()
    private let mofaChatService = MOFAChatService()
    private let openAIService = OpenAIService()
    private var hasLoadedDocuments = false
    
    init() {
        Task {
            await loadDocumentsFromDocsFolder()
        }
    }
    
    private func loadDocumentsFromDocsFolder() async {
        isProcessingDocuments = true
        
        // Get the documents directory path
        let fileManager = FileManager.default
        let docsPath = (try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true))?
            .appendingPathComponent("docs")
        
        guard let docsURL = docsPath else {
            isProcessingDocuments = false
            return
        }
        
        // Create docs directory if it doesn't exist
        if !fileManager.fileExists(atPath: docsURL.path) {
            try? fileManager.createDirectory(at: docsURL, withIntermediateDirectories: true)
        }
        
        // Get all files in the docs directory
        guard let files = try? fileManager.contentsOfDirectory(at: docsURL, includingPropertiesForKeys: nil) else {
            isProcessingDocuments = false
            return
        }
        
        let supportedExtensions = ["pdf", "csv"]
        let documentFiles = files.filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
        
        if documentFiles.isEmpty {
            print("No documents found in docs folder")
            isProcessingDocuments = false
            return
        }
        
        // Process each document
        var successCount = 0
        for url in documentFiles {
            do {
                try await vectorDBService.processAndEmbedDocument(at: url)
                successCount += 1
            } catch {
                print("Error processing document \(url.lastPathComponent): \(error)")
            }
        }
        
        hasLoadedDocuments = successCount > 0
        isProcessingDocuments = false
    }
    
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(content: inputMessage, isUser: true)
        messages.append(userMessage)
        
        let userMessageContent = inputMessage
        inputMessage = ""
        
        Task {
            isLoading = true
            do {
                let response: String
                
                if hasLoadedDocuments {
                    // Try to find relevant documents first
                    let relevantDocs = try await vectorDBService.findSimilarDocuments(for: userMessageContent)
                    
                    if !relevantDocs.isEmpty {
                        // Create context from relevant documents
                        let context = relevantDocs.map { doc in
                            """
                            Content from \(doc.sourceFile):
                            \(doc.content)
                            """
                        }.joined(separator: "\n\n")
                        
                        // Create prompt with context
                        let prompt = """
                        Context information is below.
                        ---------------------
                        \(context)
                        ---------------------
                        Given the context information and not prior knowledge, answer the question: \(userMessageContent)
                        If the context doesn't contain the answer, respond as a general MOFA assistant.
                        """
                        
                        response = try await openAIService.generateResponse(for: prompt)
                    } else {
                        // Fallback to general MOFA chat if no relevant documents found
                        response = try await mofaChatService.generateResponse(for: userMessageContent)
                    }
                } else {
                    // Use general MOFA chat if no documents are loaded
                    response = try await mofaChatService.generateResponse(for: userMessageContent)
                }
                
                let assistantMessage = Message(content: response, isUser: false)
                messages.append(assistantMessage)
            } catch {
                print("Error generating response: \(error)")
                let errorMessage = Message(content: "Sorry, I encountered an error. Please try again.", isUser: false)
                messages.append(errorMessage)
            }
            isLoading = false
        }
    }
}
