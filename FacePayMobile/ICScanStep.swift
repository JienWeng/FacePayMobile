//
//  ICScanStep.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI
import Vision

struct ICScanStep: View {
    let onNext: () -> Void
    
    @State private var showingCamera = false
    @State private var showingResults = false
    @State private var extractedICNumber = ""
    @State private var extractedName = ""
    @State private var isProcessing = false
    @State private var showingNameEdit = false
    @State private var editableName = ""
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 30) {
            if !showingResults {
                // Scan instruction
                VStack(spacing: 20) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60, weight: .black))
                        .foregroundColor(.primaryYellow)
                    
                    Text("Position your IC")
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .foregroundColor(.black)
                    
                    Text("Make sure your IC is clearly visible")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                if isProcessing {
                    VStack(spacing: 20) {
                        ZStack {
                            // Background circle
                            Circle()
                                .stroke(Color.primaryYellow.opacity(0.3), lineWidth: 4)
                                .frame(width: 80, height: 80)
                            
                            // Spinning circle
                            Circle()
                                .trim(from: 0.0, to: 0.75)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.primaryYellow, .orange]),
                                        startPoint: .topTrailing,
                                        endPoint: .bottomLeading
                                    ),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(rotationAngle))
                                .onAppear {
                                    withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                                        rotationAngle = 360
                                    }
                                }
                            
                            // Center icon
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.primaryYellow)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Processing IC...")
                                .font(.system(size: 18, weight: .semibold, design: .default))
                                .foregroundColor(.black)
                            
                            Text("Extracting information")
                                .font(.system(size: 14, weight: .medium, design: .default))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
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
                            .font(.system(size: 18, weight: .bold, design: .default))
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
                .disabled(isProcessing)
            } else {
                // Results view
                ICResultsView(
                    icNumber: extractedICNumber,
                    name: $editableName,
                    showingNameEdit: $showingNameEdit,
                    onRetake: {
                        showingResults = false
                        extractedICNumber = ""
                        extractedName = ""
                        editableName = ""
                    },
                    onConfirm: onNext
                )
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            ICCameraView(
                onImageCaptured: { image in
                    showingCamera = false
                    isProcessing = true
                    extractICDataFromImage(image)
                },
                onDismiss: {
                    showingCamera = false
                }
            )
        }
    }
    
    private func extractICDataFromImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            isProcessing = false
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    isProcessing = false
                }
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            DispatchQueue.main.async {
                processExtractedText(recognizedStrings)
            }
        }
        
        request.recognitionLevel = .accurate
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
    
    private func processExtractedText(_ recognizedStrings: [String]) {
        var foundICNumber = ""
        var foundName = ""
        
        // IC Number regex pattern: xxxxxx-xx-xxxx
        let icPattern = #"(\d{6}-\d{2}-\d{4})"#
        let icRegex = try! NSRegularExpression(pattern: icPattern)
        
        // Find IC number
        for text in recognizedStrings {
            let range = NSRange(location: 0, length: text.utf16.count)
            if let match = icRegex.firstMatch(in: text, options: [], range: range) {
                if let icRange = Range(match.range, in: text) {
                    foundICNumber = String(text[icRange])
                    break
                }
            }
        }
        
        // Find name (all capital letters, not common Malaysian words)
        let excludedWords = ["MYKAD", "JALAN", "MALAYSIA", "WARGANEGARA", "LELAKI", "PEREMPUAN", "ISLAM", "BUDDHA", "KRISTIAN", "HINDU", "SIKH", "CINA", "MELAYU", "INDIA"]
        
        for text in recognizedStrings {
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if text is all capital letters and contains only letters and spaces
            let namePattern = #"^[A-Z\s]+$"#
            let nameRegex = try! NSRegularExpression(pattern: namePattern)
            let nameRange = NSRange(location: 0, length: trimmedText.utf16.count)
            
            if nameRegex.firstMatch(in: trimmedText, options: [], range: nameRange) != nil {
                // Check if it's not an excluded word and has reasonable length
                let isExcluded = excludedWords.contains { excludedWord in
                    trimmedText.contains(excludedWord)
                }
                
                if !isExcluded && trimmedText.count >= 3 && trimmedText.count <= 50 {
                    // Additional check: should contain at least one space (first and last name)
                    if trimmedText.contains(" ") {
                        foundName = trimmedText
                        break
                    }
                }
            }
        }
        
        // Check if we found valid IC number
        if !foundICNumber.isEmpty {
            extractedICNumber = foundICNumber
            extractedName = foundName
            editableName = foundName
            showingResults = true
        } else {
            // Scan again if no valid IC number found
            extractedICNumber = ""
            extractedName = ""
            editableName = ""
        }
        
        isProcessing = false
    }
}

struct ICResultsView: View {
    let icNumber: String
    @Binding var name: String
    @Binding var showingNameEdit: Bool
    let onRetake: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text("IC Information")
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundColor(.black)
            
            VStack(spacing: 20) {
                // IC Number (non-editable)
                VStack(alignment: .leading, spacing: 8) {
                    Text("IC Number")
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.black)
                    
                    HStack {
                        Text(icNumber)
                            .font(.system(size: 18, weight: .medium, design: .default))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                // Name (editable)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Name")
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.black)
                    
                    if showingNameEdit {
                        VStack(spacing: 12) {
                            TextField("Enter your full name", text: $name)
                                .font(.system(size: 18, weight: .medium, design: .default))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.primaryYellow, lineWidth: 2)
                                )
                                .cornerRadius(8)
                            
                            HStack(spacing: 12) {
                                Button("Cancel") {
                                    showingNameEdit = false
                                }
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(6)
                                
                                Button("Save") {
                                    showingNameEdit = false
                                }
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.primaryYellow)
                                .cornerRadius(6)
                            }
                        }
                    } else {
                        Button(action: {
                            showingNameEdit = true
                        }) {
                            HStack {
                                Text(name.isEmpty ? "Tap to enter name" : name)
                                    .font(.system(size: 18, weight: .medium, design: .default))
                                    .foregroundColor(name.isEmpty ? .gray : .black)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Image(systemName: "pencil")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primaryYellow)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 16) {
                Button(action: onRetake) {
                    Text("Scan Again")
                        .font(.system(size: 16, weight: .medium, design: .default))
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
                    Text("Continue")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(!name.isEmpty ? Color.primaryYellow : Color.gray.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 3)
                        )
                        .cornerRadius(12)
                }
                .disabled(name.isEmpty)
            }
            .padding(.horizontal, 32)
        }
    }
}
