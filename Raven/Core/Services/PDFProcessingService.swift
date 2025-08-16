//
//  PDFProcessingService.swift
//  Parrot
//
//  Created by Eldar Tutnjic on 16.08.25.
//

import PDFKit

// MARK: - PDFKit for PDF Files

class PDFProcessingService {
    // MARK: - PDF Text Extraction

    func extractTextFromPDF(
        _ pdfURL: URL
    ) -> String? {
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            return nil
        }

        var extractedText = ""

        for pageIndex in 0 ..< pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex),
               let pageText = page.string
            {
                extractedText += pageText + "\n"
            }
        }

        return extractedText.isEmpty ? nil : extractedText
    }
}
