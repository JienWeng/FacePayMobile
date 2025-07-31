//
//  FaceRegistrationStep.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI
import Vision
import AVFoundation

struct FaceRegistrationStep: View {
    let onNext: () -> Void
    @State private var showingCamera = false
    @State private var faceRegistered = false
    @State private var registrationProgress: Double = 0.0
    
    var body: some View {
        VStack(spacing: 30) {
            if !showingCamera && !faceRegistered {
                // Face registration instruction
                VStack(spacing: 20) {
                    Image(systemName: "faceid")
                        .font(.system(size: 60, weight: .black))
                        .foregroundColor(.primaryYellow)
                    
                    Text("Register Your Face")
                        .font(.custom("Graphik-Black", size: 24))
                        .fontWeight(.black)
                        .foregroundColor(.black)
                    
                    Text("Look straight at the camera for 4 seconds")
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
                        Text("Start Face Registration")
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
            } else if faceRegistered {
                // Registration complete
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60, weight: .black))
                        .foregroundColor(.green)
                    
                    Text("Face Registered!")
                        .font(.custom("Graphik-Black", size: 24))
                        .fontWeight(.black)
                        .foregroundColor(.black)
                    
                    Text("Your face has been successfully registered")
                        .font(.custom("Graphik-Bold", size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                Button(action: onNext) {
                    Text("Continue")
                        .font(.custom("Graphik-Black", size: 18))
                        .fontWeight(.black)
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
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            FaceCameraView(
                onFaceRegistered: {
                    faceRegistered = true
                    showingCamera = false
                },
                onDismiss: {
                    showingCamera = false
                }
            )
        }
    }
}

#Preview {
    FaceRegistrationStep(onNext: {})
}

struct FaceLandmarksPreviewView: View {
    let image: UIImage?
    let landmarks: [VNFaceLandmarks2D]
    let faceDetected: Bool
    let onRetake: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Face Registration")
                .font(.custom("Graphik-Bold", size: 24))
                .foregroundColor(.black)
            
            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(faceDetected ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                
                Text(faceDetected ? "Face Detected" : "No Face Detected")
                    .font(.custom("Graphik-Bold", size: 16))
                    .foregroundColor(faceDetected ? .green : .red)
            }
            
            // Image preview with landmarks overlay
            if let image = image {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                    
                    // Landmarks overlay
                    FaceLandmarksOverlay(
                        image: image,
                        landmarks: landmarks
                    )
                    .frame(maxHeight: 300)
                    
                    // Frame overlay
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(faceDetected ? Color.green : Color.red, lineWidth: 3)
                        .frame(maxHeight: 300)
                }
                .padding(.horizontal, 20)
            }
            
            // Landmarks info
            if faceDetected && !landmarks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected Features:")
                        .font(.custom("Graphik-Bold", size: 16))
                        .foregroundColor(.black)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            if landmarks.first?.allPoints != nil {
                                Text("✓ Face outline detected")
                            }
                            if landmarks.first?.leftEye != nil {
                                Text("✓ Left eye detected")
                            }
                            if landmarks.first?.rightEye != nil {
                                Text("✓ Right eye detected")
                            }
                            if landmarks.first?.nose != nil {
                                Text("✓ Nose detected")
                            }
                            if landmarks.first?.outerLips != nil {
                                Text("✓ Lips detected")
                            }
                        }
                        .font(.custom("Graphik-Bold", size: 14))
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
                        .font(.custom("Graphik-Bold", size: 16))
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
                    Text(faceDetected ? "Register Face" : "Skip for Now")
                        .font(.custom("Graphik-Bold", size: 16))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(faceDetected ? Color.primaryYellow : Color.gray.opacity(0.3))
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
    FaceRegistrationStep(onNext: {})
}
