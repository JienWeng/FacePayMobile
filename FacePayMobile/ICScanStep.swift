//
//  ICScanStep.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI
import AVFoundation
import Vision

struct ICScanStep: View {
    let onNext: () -> Void
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var extractedText: String = ""
    @State private var showingPreview = false
    
    var body: some View {
        VStack(spacing: 30) {
            if !showingPreview {
                // Scan instruction
                VStack(spacing: 20) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60, weight: .black))
                        .foregroundColor(.primaryYellow)
                    
                    Text("Position your IC")
                        .font(.custom("Graphik-Black", size: 24))
                        .fontWeight(.black)
                        .foregroundColor(.black)
                    
                    Text("Make sure your IC is clearly visible")
                        .font(.custom("Graphik-Bold", size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Camera button
                Button(action: {
                    showingCamera = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera")
                            .font(.system(size: 20, weight: .black))
                        Text("Open Camera")
                            .font(.custom("Graphik-Black", size: 18))
                            .fontWeight(.black)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.primaryYellow)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal, 32)
            } else {
                // Preview captured image
                ICPreviewView(
                    image: capturedImage,
                    extractedText: extractedText,
                    onRetake: {
                        showingPreview = false
                        capturedImage = nil
                        extractedText = ""
                    },
                    onConfirm: onNext
                )
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            ICCameraView(
                onImageCaptured: { image in
                    capturedImage = image
                    extractTextFromImage(image)
                    showingCamera = false
                    showingPreview = true
                },
                onDismiss: {
                    showingCamera = false
                }
            )
        }
    }
    
    private func extractTextFromImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            DispatchQueue.main.async {
                extractedText = recognizedStrings.joined(separator: "\n")
            }
        }
        
        request.recognitionLevel = .accurate
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
}

struct ICPreviewView: View {
    let image: UIImage?
    let extractedText: String
    let onRetake: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Preview")
                .font(.custom("Graphik-Black", size: 24))
                .fontWeight(.black)
                .foregroundColor(.black)
            
            // Image preview with frame
            if let image = image {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                    
                    // Frame overlay
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primaryYellow, lineWidth: 3)
                        .frame(maxHeight: 200)
                }
                .padding(.horizontal, 20)
            }
            
            // Extracted text preview
            if !extractedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected Information:")
                        .font(.custom("Graphik-Black", size: 16))
                        .fontWeight(.black)
                        .foregroundColor(.black)
                    
                    ScrollView {
                        Text(extractedText)
                            .font(.custom("Graphik-Bold", size: 14))
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 100)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 16) {
                Button(action: onRetake) {
                    Text("Retake")
                        .font(.custom("Graphik-Black", size: 16))
                        .fontWeight(.black)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 3)
                        )
                        .cornerRadius(12)
                }
                
                Button(action: onConfirm) {
                    Text("Looks Good")
                        .font(.custom("Graphik-Black", size: 16))
                        .fontWeight(.black)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.primaryYellow)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 3)
                        )
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    ICScanStep(onNext: {})
}
