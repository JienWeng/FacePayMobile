//
//  FaceDataManager.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import Foundation
import Vision

struct FaceFeatures: Codable {
    let faceObservation: Data
    let landmarks: [String: [[Double]]]
    let boundingBox: CGRect
    let quality: Float
    let timestamp: Date
    
    init(observation: VNFaceObservation) {
        // Store the face observation data
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: observation, requiringSecureCoding: false) {
            self.faceObservation = data
        } else {
            self.faceObservation = Data()
        }
        
        // Extract detailed landmarks
        var landmarkData: [String: [[Double]]] = [:]
        
        if let landmarks = observation.landmarks {
            if let allPoints = landmarks.allPoints {
                landmarkData["allPoints"] = allPoints.pointsInImage(imageSize: CGSize(width: 1, height: 1)).map { [Double($0.x), Double($0.y)] }
            }
            if let leftEye = landmarks.leftEye {
                landmarkData["leftEye"] = leftEye.pointsInImage(imageSize: CGSize(width: 1, height: 1)).map { [Double($0.x), Double($0.y)] }
            }
            if let rightEye = landmarks.rightEye {
                landmarkData["rightEye"] = rightEye.pointsInImage(imageSize: CGSize(width: 1, height: 1)).map { [Double($0.x), Double($0.y)] }
            }
            if let nose = landmarks.nose {
                landmarkData["nose"] = nose.pointsInImage(imageSize: CGSize(width: 1, height: 1)).map { [Double($0.x), Double($0.y)] }
            }
            if let outerLips = landmarks.outerLips {
                landmarkData["outerLips"] = outerLips.pointsInImage(imageSize: CGSize(width: 1, height: 1)).map { [Double($0.x), Double($0.y)] }
            }
            if let innerLips = landmarks.innerLips {
                landmarkData["innerLips"] = innerLips.pointsInImage(imageSize: CGSize(width: 1, height: 1)).map { [Double($0.x), Double($0.y)] }
            }
            if let leftEyebrow = landmarks.leftEyebrow {
                landmarkData["leftEyebrow"] = leftEyebrow.pointsInImage(imageSize: CGSize(width: 1, height: 1)).map { [Double($0.x), Double($0.y)] }
            }
            if let rightEyebrow = landmarks.rightEyebrow {
                landmarkData["rightEyebrow"] = rightEyebrow.pointsInImage(imageSize: CGSize(width: 1, height: 1)).map { [Double($0.x), Double($0.y)] }
            }
        }
        
        self.landmarks = landmarkData
        self.boundingBox = observation.boundingBox
        self.quality = observation.faceCaptureQuality ?? 0.0
        self.timestamp = Date()
    }
}

class FaceDataManager: ObservableObject {
    @Published var registeredFaceFeatures: FaceFeatures?
    @Published var isRegistered: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let faceDataKey = "RegisteredFaceFeatures"
    
    init() {
        loadStoredFaceFeatures()
    }
    
    func registerFace(_ features: FaceFeatures) {
        self.registeredFaceFeatures = features
        self.isRegistered = true
        saveFaceFeatures(features)
    }
    
    func compareFaces(_ newFeatures: FaceFeatures) -> Float {
        guard let registered = registeredFaceFeatures else { return 0.0 }
        
        // Simple landmark comparison - in production you'd use more sophisticated algorithms
        var similarity: Float = 0.0
        var comparedLandmarks = 0
        
        for (landmarkType, registeredPoints) in registered.landmarks {
            if let newPoints = newFeatures.landmarks[landmarkType] {
                let landmarkSimilarity = calculateLandmarkSimilarity(registeredPoints, newPoints)
                similarity += landmarkSimilarity
                comparedLandmarks += 1
            }
        }
        
        if comparedLandmarks > 0 {
            similarity /= Float(comparedLandmarks)
        }
        
        // Factor in bounding box similarity
        let boxSimilarity = calculateBoundingBoxSimilarity(registered.boundingBox, newFeatures.boundingBox)
        similarity = (similarity * 0.8) + (boxSimilarity * 0.2)
        
        return similarity
    }
    
    private func calculateLandmarkSimilarity(_ points1: [[Double]], _ points2: [[Double]]) -> Float {
        guard points1.count == points2.count else { return 0.0 }
        
        var totalDistance: Double = 0.0
        for i in 0..<points1.count {
            let dx = points1[i][0] - points2[i][0]
            let dy = points1[i][1] - points2[i][1]
            totalDistance += sqrt(dx * dx + dy * dy)
        }
        
        let averageDistance = totalDistance / Double(points1.count)
        return max(0.0, 1.0 - Float(averageDistance))
    }
    
    private func calculateBoundingBoxSimilarity(_ box1: CGRect, _ box2: CGRect) -> Float {
        let intersection = box1.intersection(box2)
        let union = box1.union(box2)
        
        if union.width * union.height == 0 { return 0.0 }
        
        let iou = (intersection.width * intersection.height) / (union.width * union.height)
        return Float(iou)
    }
    
    private func saveFaceFeatures(_ features: FaceFeatures) {
        if let data = try? JSONEncoder().encode(features) {
            userDefaults.set(data, forKey: faceDataKey)
        }
    }
    
    private func loadStoredFaceFeatures() {
        if let data = userDefaults.data(forKey: faceDataKey),
           let features = try? JSONDecoder().decode(FaceFeatures.self, from: data) {
            self.registeredFaceFeatures = features
            self.isRegistered = true
        }
    }
    
    func clearFaceData() {
        registeredFaceFeatures = nil
        isRegistered = false
        userDefaults.removeObject(forKey: faceDataKey)
    }
}
