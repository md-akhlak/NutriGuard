import Foundation
import Vision
import VisionKit
import UIKit

@MainActor
class MenuScannerViewModel: ObservableObject {
    @Published var scannedText: String = ""
    @Published var analyzedItems: [(name: String, safety: FoodSafetyLevel)] = []
    @Published var isScanning = false
    @Published var errorMessage: String?
    @Published var selectedImage: UIImage?
    
    private var userProfile: UserProfile
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
    }
    
    func updateUserProfile(_ newProfile: UserProfile) {
        self.userProfile = newProfile
        // Re-analyze items if needed with the new profile
        if !analyzedItems.isEmpty {
            // Implement re-analysis logic here
            // This would depend on how you're storing the original menu items
        }
    }
    
    func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            errorMessage = "Failed to process image"
            return
        }
        
        selectedImage = image
        isScanning = true
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isScanning = false
                }
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    self.errorMessage = "No text found in image"
                    self.isScanning = false
                }
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            DispatchQueue.main.async {
                self.scannedText = recognizedText
                self.analyzeScannedMenu(text: recognizedText)
                self.isScanning = false
            }
        }
        
        request.recognitionLevel = .accurate
        
        do {
            try requestHandler.perform([request])
        } catch {
            errorMessage = error.localizedDescription
            isScanning = false
        }
    }
    
    func analyzeScannedMenu(text: String) {
        // Split text into potential menu items
        let lines = text.components(separatedBy: .newlines)
        analyzedItems = []
        
        for line in lines where !line.isEmpty {
            // Basic ingredient extraction (can be enhanced with NLP)
            let ingredients = line.components(separatedBy: CharacterSet(charactersIn: ",()/"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            let safety = userProfile.checkFoodSafety(ingredients: ingredients)
            analyzedItems.append((name: line, safety: safety))
        }
    }
    
    func clearScan() {
        selectedImage = nil
        analyzedItems = []
        scannedText = ""
        isScanning = false
        errorMessage = nil
    }
} 