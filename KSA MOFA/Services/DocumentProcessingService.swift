import Foundation
import PDFKit
import UniformTypeIdentifiers

enum DocumentProcessingError: Error {
    case pdfLoadError
    case pdfAccessError
    case csvParseError
    case unsupportedFileType
    case invalidPDF
    case invalidCSV
    case fileNotFound
    
    var localizedDescription: String {
        switch self {
        case .pdfLoadError:
            return "Could not load PDF file"
        case .pdfAccessError:
            return "Could not access PDF content"
        case .csvParseError:
            return "Could not parse CSV file"
        case .unsupportedFileType:
            return "Unsupported file type"
        case .invalidPDF:
            return "Invalid PDF file"
        case .invalidCSV:
            return "Invalid CSV file"
        case .fileNotFound:
            return "File not found"
        }
    }
}

struct ProcessedDocument {
    let content: String
    let metadata: [String: String]
    let sourceFile: String
}

class DocumentProcessingService {
    
    func processDocument(at url: URL) throws -> ProcessedDocument {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return try processPDF(at: url)
        case "csv":
            return try processCSV(at: url)
        case "txt":
            return try processTXT(at: url)
        default:
            throw DocumentProcessingError.unsupportedFileType
        }
    }
    
    private func processPDF(at url: URL) throws -> ProcessedDocument {
        // First try to load the PDF data
        guard let pdfData = try? Data(contentsOf: url) else {
            throw DocumentProcessingError.pdfAccessError
        }
        
        // Create PDF document from data
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            throw DocumentProcessingError.pdfLoadError
        }
        
        var content = ""
        
        // Process each page
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            // Try multiple methods to extract text
            if let pageContent = page.string {
                content += pageContent + "\n"
            } else if let attributedString = page.attributedString {
                content += attributedString.string + "\n"
            }
        }
        
        // If we couldn't get any content, try an alternative method
        if content.isEmpty {
            content = try extractTextFromPDFAlternative(pdfDocument)
        }
        
        let metadata: [String: String] = [
            "type": "pdf",
            "filename": url.lastPathComponent,
            "pageCount": String(pdfDocument.pageCount)
        ]
        
        return ProcessedDocument(content: content, metadata: metadata, sourceFile: url.lastPathComponent)
    }
    
    private func extractTextFromPDFAlternative(_ pdfDocument: PDFDocument) throws -> String {
        var content = ""
        
        for pageIndex in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex),
               let attributedString = page.attributedString {
                content += attributedString.string + "\n"
            }
        }
        
        if content.isEmpty {
            throw DocumentProcessingError.pdfAccessError
        }
        
        return content
    }
    
    private func processCSV(at url: URL) throws -> ProcessedDocument {
        guard let csvString = try? String(contentsOf: url, encoding: .utf8) else {
            throw DocumentProcessingError.csvParseError
        }
        
        let rows = csvString.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
        
        guard !rows.isEmpty else {
            throw DocumentProcessingError.csvParseError
        }
        
        var content = ""
        var headers: [String] = []
        
        for (index, row) in rows.enumerated() {
            let columns = row.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            if index == 0 {
                headers = columns
                continue
            }
            
            // Create structured content from CSV
            if columns.count == headers.count {
                let rowContent = zip(headers, columns)
                    .map { "\($0): \($1)" }
                    .joined(separator: "\n")
                content += rowContent + "\n\n"
            }
        }
        
        let metadata: [String: String] = [
            "type": "csv",
            "filename": url.lastPathComponent,
            "rowCount": String(rows.count)
        ]
        
        return ProcessedDocument(content: content, metadata: metadata, sourceFile: url.lastPathComponent)
    }
    
    private func processTXT(at url: URL) throws -> ProcessedDocument {
        guard let txtString = try? String(contentsOf: url, encoding: .utf8) else {
            throw DocumentProcessingError.fileNotFound
        }
        
        let metadata: [String: String] = [
            "type": "txt",
            "filename": url.lastPathComponent
        ]
        
        return ProcessedDocument(content: txtString, metadata: metadata, sourceFile: url.lastPathComponent)
    }
}
