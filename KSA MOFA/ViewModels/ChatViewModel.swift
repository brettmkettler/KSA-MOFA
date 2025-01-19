import Foundation
import UIKit

class ChatViewModel: ObservableObject {
    private let openAIService = OpenAIService()
    private let fileManager = FileManager.default
    
    @Published var messages: [Message] = []
    @Published var inputMessage: String = ""
    @Published var isLoading = false
    @Published var isProcessingDocuments = false
    
    init() {
        loadDocuments()
    }
    
    private func loadDocuments() {
        isProcessingDocuments = true
        Task {
            do {
                // Get the app's documents directory
                guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    print("Could not access documents directory")
                    await MainActor.run { self.isProcessingDocuments = false }
                    return
                }
                
                let docsFolder = documentsPath.appendingPathComponent("Docs")
                
                // Create Docs directory if it doesn't exist
                if !fileManager.fileExists(atPath: docsFolder.path) {
                    try fileManager.createDirectory(at: docsFolder, withIntermediateDirectories: true)
                    
                    // Copy default document if it exists
                    if let defaultDocURL = Bundle.main.url(forResource: "mofa_services", withExtension: "txt") {
                        let destinationURL = docsFolder.appendingPathComponent("mofa_services.txt")
                        try fileManager.copyItem(at: defaultDocURL, to: destinationURL)
                        print("Copied default document to: \(destinationURL.path)")
                    }
                }
                
                // Get all files in the Docs directory
                let files = try fileManager.contentsOfDirectory(at: docsFolder, includingPropertiesForKeys: nil)
                let supportedExtensions = ["pdf", "csv", "txt"]
                let documentFiles = files.filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
                
                print("Found \(documentFiles.count) documents in Docs folder")
                
                // Process each document's content for context
                for documentURL in documentFiles {
                    if let content = try? String(contentsOf: documentURL, encoding: .utf8) {
                        print("Processed document: \(documentURL.lastPathComponent)")
                        // Here you would typically process the content into your knowledge base
                        // For now, we're just loading the documents
                    }
                }
            } catch {
                print("Error processing documents: \(error)")
            }
            
            await MainActor.run {
                isProcessingDocuments = false
            }
        }
    }
    
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(content: .text(inputMessage), isUser: true)
        messages.append(userMessage)
        
        let userQuery = inputMessage
        inputMessage = ""
        isLoading = true
        
        Task {
            do {
                let response = try await openAIService.generateResponse(
                    for: userQuery,
                    withContext: nil,
                    previousMessages: Array(messages.dropLast())
                )
                await MainActor.run {
                    messages.append(Message(content: .text(response), isUser: false))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    messages.append(Message(content: .text("I apologize, but I encountered an error while processing your request. Please try again."), isUser: false))
                    isLoading = false
                }
            }
        }
    }
    
    func sendImage(_ image: UIImage) {
        let userMessage = Message(content: .image(image), isUser: true)
        messages.append(userMessage)
        isLoading = true
        
        Task {
            do {
                let analysis = try await openAIService.analyzeImage(image)
                await MainActor.run {
                    messages.append(Message(content: .text(analysis), isUser: false))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    messages.append(Message(content: .text("I apologize, but I couldn't analyze the image. Please try again."), isUser: false))
                    isLoading = false
                }
            }
        }
    }
}
