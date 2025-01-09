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
        
        let fileManager = FileManager.default
        
        // Get the app's documents directory
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not access documents directory")
            isProcessingDocuments = false
            return
        }
        
        let docsFolder = documentsPath.appendingPathComponent("Docs")
        
        // Create Docs directory if it doesn't exist
        if !fileManager.fileExists(atPath: docsFolder.path) {
            do {
                try fileManager.createDirectory(at: docsFolder, withIntermediateDirectories: true)
                
                // Copy default document if it exists
                if let defaultDocURL = Bundle.main.url(forResource: "mofa_services", withExtension: "txt") {
                    let destinationURL = docsFolder.appendingPathComponent("mofa_services.txt")
                    try fileManager.copyItem(at: defaultDocURL, to: destinationURL)
                    print("Copied default document to: \(destinationURL.path)")
                } else {
                    print("Default document not found in bundle")
                }
            } catch {
                print("Error setting up Docs folder: \(error.localizedDescription)")
            }
        }
        
        // Get all files in the Docs directory
        do {
            let files = try fileManager.contentsOfDirectory(at: docsFolder, includingPropertiesForKeys: nil)
            let supportedExtensions = ["pdf", "csv", "txt"]
            let documentFiles = files.filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
            
            if documentFiles.isEmpty {
                print("No documents found in Docs folder")
                isProcessingDocuments = false
                return
            }
            
            print("Found \(documentFiles.count) documents in Docs folder")
            print("Document paths: \(documentFiles.map { $0.path })")
            
            // Process all documents
            await vectorDBService.processDocuments(urls: documentFiles)
            hasLoadedDocuments = true
            
        } catch {
            print("Error reading Docs folder: \(error.localizedDescription)")
        }
        
        isProcessingDocuments = false
    }
    
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(content: inputMessage, isUser: true)
        messages.append(userMessage)
        
        let userQuery = inputMessage
        inputMessage = ""
        isLoading = true
        
        Task {
            do {
                let response = try await openAIService.generateResponse(for: userQuery)
                await MainActor.run {
                    messages.append(Message(content: response, isUser: false))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    messages.append(Message(content: "I apologize, but I encountered an error while processing your request. Please try again.", isUser: false))
                    isLoading = false
                }
            }
        }
    }
}
