//
//  FaceSignInCameraView.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI
import AVFoundation
import Vision

struct FaceSignInCameraView: UIViewControllerRepresentable {
    let onSignInSuccess: () -> Void
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> FaceSignInCameraViewController {
        let controller = FaceSignInCameraViewController()
        controller.onSignInSuccess = onSignInSuccess
        controller.onDismiss = onDismiss
        return controller
    }
    
    func updateUIViewController(_ uiViewController: FaceSignInCameraViewController, context: Context) {}
}

class FaceSignInCameraViewController: UIViewController {
    var onSignInSuccess: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    
    private let frameView = UIView()
    private let dismissButton = UIButton()
    private let statusLabel = UILabel()
    private let progressView = UIProgressView()
    private let faceMeshOverlay = CAShapeLayer()
    
    private var faceDetected = false
    private var faceInCircle = false
    private var signInTimer: Timer?
    private var signInProgress: Float = 0.0
    private let signInDuration: Float = 2.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSession()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopSession()
    }
    
    deinit {
        signInTimer?.invalidate()
        signInTimer = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: frontCamera) else {
            return
        }
        
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)
    }
    
    private func setupUI() {
        // White mask overlay to focus on face circle
        let maskLayer = CAShapeLayer()
        let circlePath = UIBezierPath(rect: view.bounds)
        let circleFrame = CGRect(x: view.bounds.midX - 150, y: view.bounds.midY - 240, width: 300, height: 300)
        let circlePath2 = UIBezierPath(ovalIn: circleFrame)
        circlePath.append(circlePath2.reversing())
        maskLayer.path = circlePath.cgPath
        maskLayer.fillColor = UIColor.white.cgColor
        view.layer.addSublayer(maskLayer)
        
        // Face mesh overlay for connected landmarks
        faceMeshOverlay.strokeColor = UIColor.primaryYellow.cgColor
        faceMeshOverlay.lineWidth = 10
        faceMeshOverlay.fillColor = UIColor.clear.cgColor
        view.layer.addSublayer(faceMeshOverlay)
        
        // Face frame guide (circular)
        frameView.backgroundColor = UIColor.clear
        frameView.layer.borderColor = UIColor.primaryYellow.withAlphaComponent(0.8).cgColor
        frameView.layer.borderWidth = 3
        frameView.layer.cornerRadius = 150
        frameView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(frameView)
        
        // Progress view
        progressView.progressTintColor = UIColor.primaryYellow
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        progressView.transform = CGAffineTransform(scaleX: 1, y: 3)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        // Status label
        statusLabel.textColor = .white
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .black)
        statusLabel.layer.cornerRadius = 8
        statusLabel.clipsToBounds = true
        statusLabel.text = "Position your face in the circle"
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // Dismiss button
        dismissButton.backgroundColor = UIColor.white
        dismissButton.layer.borderColor = UIColor.black.cgColor
        dismissButton.layer.borderWidth = 3
        dismissButton.layer.cornerRadius = 25
        dismissButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        dismissButton.tintColor = .black
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.addTarget(self, action: #selector(dismissCamera), for: .touchUpInside)
        view.addSubview(dismissButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            frameView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            frameView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            frameView.widthAnchor.constraint(equalToConstant: 300),
            frameView.heightAnchor.constraint(equalToConstant: 300),
            
            progressView.topAnchor.constraint(equalTo: frameView.bottomAnchor, constant: 20),
            progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 200),
            progressView.heightAnchor.constraint(equalToConstant: 8),
            
            statusLabel.bottomAnchor.constraint(equalTo: frameView.topAnchor, constant: -20),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.heightAnchor.constraint(equalToConstant: 40),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            dismissButton.widthAnchor.constraint(equalToConstant: 50),
            dismissButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    private func stopSession() {
        captureSession.stopRunning()
    }
    
    @objc private func dismissCamera() {
        signInTimer?.invalidate()
        onDismiss?()
    }
    
    private func startSignInTimer() {
        signInTimer?.invalidate()
        signInProgress = 0.0
        progressView.progress = 0.0
        
        signInTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else { 
                timer.invalidate()
                return 
            }
            
            guard self.faceInCircle else {
                timer.invalidate()
                return
            }
            
            self.signInProgress += 0.1
            let remaining = max(0, Int(self.signInDuration - self.signInProgress + 1))
            
            DispatchQueue.main.async {
                self.progressView.progress = self.signInProgress / self.signInDuration
                if remaining > 0 {
                    self.statusLabel.text = "Signing in... \(remaining)"
                } else {
                    self.statusLabel.text = "Success!"
                }
            }
            
            if self.signInProgress >= self.signInDuration {
                timer.invalidate()
                DispatchQueue.main.async {
                    self.onSignInSuccess?()
                }
            }
        }
        
        if let timer = signInTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopSignInTimer() {
        signInTimer?.invalidate()
        signInTimer = nil
        signInProgress = 0.0
        DispatchQueue.main.async {
            self.progressView.progress = 0.0
            self.statusLabel.text = "Position your face in the circle"
        }
    }
    
    private func drawFaceMesh(landmarks: VNFaceLandmarks2D, in faceRect: CGRect) {
        DispatchQueue.main.async {
            let path = CGMutablePath()
            
            // Draw face contour
            if let faceContour = landmarks.faceContour {
                self.drawConnectedPointsRotated(path: path, points: faceContour.normalizedPoints, in: faceRect, closed: true)
            }
            
            // Draw left eye
            if let leftEye = landmarks.leftEye {
                self.drawConnectedPointsRotated(path: path, points: leftEye.normalizedPoints, in: faceRect, closed: true)
            }
            
            // Right eye
            if let rightEye = landmarks.rightEye {
                self.drawConnectedPointsRotated(path: path, points: rightEye.normalizedPoints, in: faceRect, closed: true)
            }
            
            // Left eyebrow
            if let leftEyebrow = landmarks.leftEyebrow {
                self.drawConnectedPointsRotated(path: path, points: leftEyebrow.normalizedPoints, in: faceRect, closed: false)
            }
            
            // Right eyebrow
            if let rightEyebrow = landmarks.rightEyebrow {
                self.drawConnectedPointsRotated(path: path, points: rightEyebrow.normalizedPoints, in: faceRect, closed: false)
            }
            
            // Nose
            if let nose = landmarks.nose {
                self.drawConnectedPointsRotated(path: path, points: nose.normalizedPoints, in: faceRect, closed: false)
            }
            
            // Outer lips
            if let outerLips = landmarks.outerLips {
                self.drawConnectedPointsRotated(path: path, points: outerLips.normalizedPoints, in: faceRect, closed: true)
            }
            
            self.faceMeshOverlay.path = path
        }
    }
    
    private func drawConnectedPointsRotated(path: CGMutablePath, points: [CGPoint], in faceRect: CGRect, closed: Bool) {
        guard !points.isEmpty else { return }
        
        let firstPoint = convertNormalizedPointRotated(points[0], to: faceRect)
        path.move(to: firstPoint)
        
        for point in points.dropFirst() {
            let screenPoint = convertNormalizedPointRotated(point, to: faceRect)
            path.addLine(to: screenPoint)
        }
        
        if closed {
            path.closeSubpath()
        }
    }
    
    private func convertNormalizedPointRotated(_ point: CGPoint, to faceRect: CGRect) -> CGPoint {
        // Rotate 90 degrees to the right
        let rotatedX = 1 - point.y
        let rotatedY = point.x
        
        let x = faceRect.minX + (rotatedX * faceRect.width)
        let y = faceRect.minY + (rotatedY * faceRect.height)
        return CGPoint(x: x, y: y)
    }
    
    private func drawConnectedPoints(path: CGMutablePath, points: [CGPoint], in faceRect: CGRect, closed: Bool) {
        guard !points.isEmpty else { return }
        
        let firstPoint = convertNormalizedPoint(points[0], to: faceRect)
        path.move(to: firstPoint)
        
        for point in points.dropFirst() {
            let screenPoint = convertNormalizedPoint(point, to: faceRect)
            path.addLine(to: screenPoint)
        }
        
        if closed {
            path.closeSubpath()
        }
    }
    
    private func convertNormalizedPoint(_ point: CGPoint, to faceRect: CGRect) -> CGPoint {
        // Correct coordinate transformation for front camera
        let x = faceRect.minX + ((1 - point.x) * faceRect.width)  // Mirror horizontally for front camera
        let y = faceRect.minY + (point.y * faceRect.height)       // Normal vertical mapping
        return CGPoint(x: x, y: y)
    }
    
    private func isFaceInCircle(_ faceRect: CGRect) -> Bool {
        let circleCenter = CGPoint(x: view.bounds.midX, y: view.bounds.midY - 50)
        let circleRadius: CGFloat = 150
        
        let faceCenter = CGPoint(x: faceRect.midX, y: faceRect.midY)
        let distance = sqrt(pow(faceCenter.x - circleCenter.x, 2) + pow(faceCenter.y - circleCenter.y, 2))
        
        return distance < circleRadius && faceRect.width > 120 && faceRect.height > 120
    }
    
    private func clearFaceMesh() {
        DispatchQueue.main.async {
            self.faceMeshOverlay.path = nil
        }
    }
}

extension FaceSignInCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let self = self else { return }
            guard let observations = request.results as? [VNFaceObservation],
                  !observations.isEmpty else {
                self.faceDetected = false
                self.faceInCircle = false
                self.stopSignInTimer()
                self.clearFaceMesh()
                DispatchQueue.main.async {
                    self.statusLabel.text = "Position your face in the circle"
                    self.statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
                }
                return
            }
            
            if let face = observations.first,
               let landmarks = face.landmarks,
               face.confidence > 0.8 {
                
                let faceBounds = face.boundingBox
                let faceRect = self.previewLayer.layerRectConverted(fromMetadataOutputRect: faceBounds)
                
                self.faceDetected = true
                let wasInCircle = self.faceInCircle
                self.faceInCircle = self.isFaceInCircle(faceRect)
                
                if self.faceInCircle {
                    if !wasInCircle {
                        DispatchQueue.main.async {
                            self.startSignInTimer()
                        }
                    }
                    
                    self.drawFaceMesh(landmarks: landmarks, in: faceRect)
                    
                    DispatchQueue.main.async {
                        self.statusLabel.backgroundColor = UIColor.green.withAlphaComponent(0.7)
                    }
                } else {
                    self.stopSignInTimer()
                    self.clearFaceMesh()
                    DispatchQueue.main.async {
                        self.statusLabel.text = "Move face into the circle"
                        self.statusLabel.backgroundColor = UIColor.orange.withAlphaComponent(0.7)
                    }
                }
            } else {
                self.faceDetected = false
                self.faceInCircle = false
                self.stopSignInTimer()
                self.clearFaceMesh()
                DispatchQueue.main.async {
                    self.statusLabel.text = "Position your face in the circle"
                    self.statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
                }
            }
        }
        
        request.revision = VNDetectFaceLandmarksRequestRevision3
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}
