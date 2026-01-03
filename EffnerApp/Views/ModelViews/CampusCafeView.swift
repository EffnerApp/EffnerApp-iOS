//
//  CampusCafeView.swift
//  EffnerApp
//
//  Created by Luis Bros on 03.01.26.
//

import SwiftUI
import PDFKit

struct CampusCafeView: View {
    @State private var pdfDocument: PDFDocument?
    @State private var isLoading = false
    @State private var loadError: Error?
    
    let pdfURL = "https://campuscafe.online/wp-content/uploads/speiseplaene/MeinCampusCaf%C3%A9_Speiseplan_Mittagsb%C3%BCffet_CampusCaf%C3%A9_Effner.pdf"
    
    var body: some View {
        BaseContentView(
            caches: [],
            navigationTitle: "Campus Café",
            errorTitle: "PDF nicht verfügbar",
            errorSystemImage: "doc.badge.exclamationmark",
            errorDescription: "Das PDF konnte nicht geladen werden. Bitte versuche es später erneut.",
            isModal: true,
            content: { _ in
                if let pdfDocument = pdfDocument {
                    PDFKitView(pdfDocument: pdfDocument)
                } else {
                    Color.clear
                        .onAppear {
                            if !isLoading {
                                loadPDF()
                            }
                        }
                }
            },
            skeletonView: {
                CampusCafeSkeletonView()
            }
        )
    }
    
    private func loadPDF() {
        guard let url = URL(string: pdfURL), !isLoading else {
            return
        }
        
        isLoading = true
        
        // Konfiguriere URLSession mit optimierten Einstellungen
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        
        let session = URLSession(configuration: configuration)
        
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        
        session.dataTask(with: request) { [self] data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("PDF Load Error: \(error.localizedDescription)")
                    loadError = error
                    return
                }
                
                guard let data = data else {
                    print("PDF Load Error: No data received")
                    return
                }
                
                if let document = PDFDocument(data: data) {
                    pdfDocument = document
                } else {
                    print("PDF Load Error: Could not create PDFDocument from data")
                }
            }
        }.resume()
    }
}

struct PDFKitView: UIViewRepresentable {
    let pdfDocument: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemBackground
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = pdfDocument
    }
}

struct CampusCafeSkeletonView: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3) { _ in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)
                    .padding(.horizontal)
            }
        }
        .redacted(reason: .placeholder)
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    CampusCafeView()
}
