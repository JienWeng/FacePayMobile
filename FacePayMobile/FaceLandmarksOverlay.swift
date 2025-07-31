//
//  FaceLandmarksOverlay.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI
import Vision

struct FaceLandmarksOverlay: View {
    let image: UIImage
    let landmarks: [VNFaceLandmarks2D]
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(Array(landmarks.enumerated()), id: \.offset) { index, landmark in
                ZStack {
                    // Face outline
                    if let faceContour = landmark.faceContour {
                        Path { path in
                            addPointsToPath(path: &path, points: faceContour.normalizedPoints, geometry: geometry)
                        }
                        .stroke(Color.primaryYellow, lineWidth: 2)
                    }
                    
                    // Left eye
                    if let leftEye = landmark.leftEye {
                        Path { path in
                            addPointsToPath(path: &path, points: leftEye.normalizedPoints, geometry: geometry, closed: true)
                        }
                        .stroke(Color.blue, lineWidth: 2)
                    }
                    
                    // Right eye
                    if let rightEye = landmark.rightEye {
                        Path { path in
                            addPointsToPath(path: &path, points: rightEye.normalizedPoints, geometry: geometry, closed: true)
                        }
                        .stroke(Color.blue, lineWidth: 2)
                    }
                    
                    // Left eyebrow
                    if let leftEyebrow = landmark.leftEyebrow {
                        Path { path in
                            addPointsToPath(path: &path, points: leftEyebrow.normalizedPoints, geometry: geometry)
                        }
                        .stroke(Color.green, lineWidth: 2)
                    }
                    
                    // Right eyebrow
                    if let rightEyebrow = landmark.rightEyebrow {
                        Path { path in
                            addPointsToPath(path: &path, points: rightEyebrow.normalizedPoints, geometry: geometry)
                        }
                        .stroke(Color.green, lineWidth: 2)
                    }
                    
                    // Nose
                    if let nose = landmark.nose {
                        Path { path in
                            addPointsToPath(path: &path, points: nose.normalizedPoints, geometry: geometry)
                        }
                        .stroke(Color.orange, lineWidth: 2)
                    }
                    
                    // Nose crest
                    if let noseCrest = landmark.noseCrest {
                        Path { path in
                            addPointsToPath(path: &path, points: noseCrest.normalizedPoints, geometry: geometry)
                        }
                        .stroke(Color.orange.opacity(0.7), lineWidth: 1.5)
                    }
                    
                    // Outer lips
                    if let outerLips = landmark.outerLips {
                        Path { path in
                            addPointsToPath(path: &path, points: outerLips.normalizedPoints, geometry: geometry, closed: true)
                        }
                        .stroke(Color.red, lineWidth: 2)
                    }
                    
                    // Inner lips
                    if let innerLips = landmark.innerLips {
                        Path { path in
                            addPointsToPath(path: &path, points: innerLips.normalizedPoints, geometry: geometry, closed: true)
                        }
                        .stroke(Color.red.opacity(0.7), lineWidth: 1.5)
                    }
                    
                    // Left pupil
                    if let leftPupil = landmark.leftPupil {
                        ForEach(Array(leftPupil.normalizedPoints.enumerated()), id: \.offset) { _, point in
                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 4, height: 4)
                                .position(normalizedPointToPosition(point: point, geometry: geometry))
                        }
                    }
                    
                    // Right pupil
                    if let rightPupil = landmark.rightPupil {
                        ForEach(Array(rightPupil.normalizedPoints.enumerated()), id: \.offset) { _, point in
                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 4, height: 4)
                                .position(normalizedPointToPosition(point: point, geometry: geometry))
                        }
                    }
                }
            }
        }
    }
    
    private func addPointsToPath(path: inout Path, points: [CGPoint], geometry: GeometryProxy, closed: Bool = false) {
        guard !points.isEmpty else { return }
        
        let firstPoint = normalizedPointToPosition(point: points[0], geometry: geometry)
        path.move(to: firstPoint)
        
        for point in points.dropFirst() {
            let position = normalizedPointToPosition(point: point, geometry: geometry)
            path.addLine(to: position)
        }
        
        if closed {
            path.closeSubpath()
        }
    }
    
    private func normalizedPointToPosition(point: CGPoint, geometry: GeometryProxy) -> CGPoint {
        // Vision coordinates are normalized and flipped
        let x = point.x * geometry.size.width
        let y = (1 - point.y) * geometry.size.height
        return CGPoint(x: x, y: y)
    }
}

#Preview {
    Rectangle()
        .fill(Color.gray.opacity(0.3))
        .frame(width: 300, height: 300)
        .overlay(
            Text("Face Landmarks Overlay")
                .foregroundColor(.black)
        )
}
