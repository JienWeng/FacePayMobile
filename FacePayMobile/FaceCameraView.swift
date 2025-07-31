//
//  FaceCameraView.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI
import AVFoundation
import Vision

struct FaceCameraView: UIViewControllerRepresentable {
    let onFaceRegistered: () -> Void
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> FaceCameraViewController {
        let controller = FaceCameraViewController()
        controller.onFaceRegistered = onFaceRegistered
        controller.onDismiss = onDismiss
        return controller
    }
    
    func updateUIViewController(_ uiViewController: FaceCameraViewController, context: Context) {}
}

class FaceCameraViewController: UIViewController {
    var onFaceRegistered: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    
    private let frameView = UIView()
    private let dismissButton = UIButton()
    private let statusLabel = UILabel()
    private let progressView = UIProgressView()
    private let landmarksOverlay = CAShapeLayer()
    
    private var faceDetected = false
    private var registrationTimer: Timer?
    private var registrationProgress: Float = 0.0
    private let registrationDuration: Float = 4.0
    
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
        registrationTimer?.invalidate()
        registrationTimer = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium // Use medium for better performance
        
        // Use front camera for face registration
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
        
        // Landmarks overlay for dots
        landmarksOverlay.fillColor = UIColor.primaryYellow.cgColor
        view.layer.addSublayer(landmarksOverlay)
        
        // Face frame guide (circular)
        frameView.backgroundColor = UIColor.clear
        frameView.layer.borderColor = UIColor.primaryYellow.withAlphaComponent(0.5).cgColor
        frameView.layer.borderWidth = 10
        frameView.layer.cornerRadius = 150 // Make it circular
        frameView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(frameView)
        
        // Progress view
        progressView.progressTintColor = UIColor.primaryYellow
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        progressView.transform = CGAffineTransform(scaleX: 1, y: 3) // Make it thicker
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
            // Face frame (circular guide)
            frameView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            frameView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            frameView.widthAnchor.constraint(equalToConstant: 300),
            frameView.heightAnchor.constraint(equalToConstant: 300),
            
            // Progress view
            progressView.topAnchor.constraint(equalTo: frameView.bottomAnchor, constant: 20),
            progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 200),
            progressView.heightAnchor.constraint(equalToConstant: 8),
            
            // Status label
            statusLabel.bottomAnchor.constraint(equalTo: frameView.topAnchor, constant: -20),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.heightAnchor.constraint(equalToConstant: 40),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            // Dismiss button
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
        registrationTimer?.invalidate()
        onDismiss?()
    }
    
    private func startRegistrationTimer() {
        registrationTimer?.invalidate()
        registrationProgress = 0.0
        progressView.progress = 0.0
        
        registrationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else { 
                timer.invalidate()
                return 
            }
            
            // Only continue if face is still detected
            guard self.faceDetected else {
                timer.invalidate()
                return
            }
            
            self.registrationProgress += 0.1
            let remaining = max(0, Int(self.registrationDuration - self.registrationProgress + 1))
            
            DispatchQueue.main.async {
                self.progressView.progress = self.registrationProgress / self.registrationDuration
                if remaining > 0 {
                    self.statusLabel.text = "Hold still... \(remaining)"
                } else {
                    self.statusLabel.text = "Processing..."
                }
            }
            
            if self.registrationProgress >= self.registrationDuration {
                timer.invalidate()
                DispatchQueue.main.async {
                    self.onFaceRegistered?()
                }
            }
        }
        
        // Ensure timer runs on main run loop
        if let timer = registrationTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopRegistrationTimer() {
        registrationTimer?.invalidate()
        registrationTimer = nil
        registrationProgress = 0.0
        DispatchQueue.main.async {
            self.progressView.progress = 0.0
            self.statusLabel.text = "Position your face in the circle"
        }
    }
    
    private func drawLandmarkDots(landmarks: VNFaceLandmarks2D, in faceRect: CGRect) {
        DispatchQueue.main.async {
            let path = CGMutablePath()
            
            // Create a grid pattern over the face area
            let gridSpacing: CGFloat = 15
            let dotSize: CGFloat = 3
            
            // Calculate grid dimensions
            let cols = Int(faceRect.width / gridSpacing)
            let rows = Int(faceRect.height / gridSpacing)
            
            // Draw grid dots within the face bounds
            for row in 0..<rows {
                for col in 0..<cols {
                    let x = faceRect.minX + (CGFloat(col) * gridSpacing)
                    let y = faceRect.minY + (CGFloat(row) * gridSpacing)
                    
                    // Check if this point is within the face contour if available
                    let point = CGPoint(x: x, y: y)
                    if self.isPointInFace(point: point, faceRect: faceRect) {
                        let dotRect = CGRect(x: x - dotSize/2, y: y - dotSize/2, width: dotSize, height: dotSize)
                        path.addEllipse(in: dotRect)
                    }
                }
            }
            
            // Add key landmark points for better accuracy
            if let faceContour = landmarks.faceContour {
                for point in faceContour.normalizedPoints {
                    let screenPoint = self.convertNormalizedPoint(point, to: faceRect)
                    let dotRect = CGRect(x: screenPoint.x - 2, y: screenPoint.y - 2, width: 4, height: 4)
                    path.addEllipse(in: dotRect)
                }
            }
            
            self.landmarksOverlay.path = path
        }
    }
    
    private func isPointInFace(point: CGPoint, faceRect: CGRect) -> Bool {
        // Simple elliptical check for face bounds
        let centerX = faceRect.midX
        let centerY = faceRect.midY
        let radiusX = faceRect.width / 2
        let radiusY = faceRect.height / 2
        
        let dx = point.x - centerX
        let dy = point.y - centerY
        
        return (dx * dx) / (radiusX * radiusX) + (dy * dy) / (radiusY * radiusY) <= 1
    }
    
    private func convertNormalizedPoint(_ point: CGPoint, to faceRect: CGRect) -> CGPoint {
        // Vision coordinates are normalized (0-1) and may need conversion
        let x = faceRect.minX + (point.x * faceRect.width)
        let y = faceRect.minY + (point.y * faceRect.height)
        return CGPoint(x: x, y: y)
    }
    
    private func clearLandmarks() {
        DispatchQueue.main.async {
            self.landmarksOverlay.path = nil
        }
    }
}

extension FaceCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let self = self else { return }
            guard let observations = request.results as? [VNFaceObservation],
                  !observations.isEmpty else {
                self.faceDetected = false
                self.stopRegistrationTimer()
                self.clearLandmarks()
                DispatchQueue.main.async {
                    self.statusLabel.text = "Position your face in the circle"
                    self.statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
                }
                return
            }
            
            if let face = observations.first,
               let landmarks = face.landmarks,
               face.confidence > 0.7 { // Add confidence threshold
                
                // Convert face bounding box to screen coordinates
                let faceBounds = face.boundingBox
                let faceRect = self.previewLayer.layerRectConverted(fromMetadataOutputRect: faceBounds)
                
                // Check if face is reasonably sized and positioned
                let minFaceSize: CGFloat = 150
                if faceRect.width > minFaceSize && faceRect.height > minFaceSize {
                    if !self.faceDetected {
                        self.faceDetected = true
                        DispatchQueue.main.async {
                            self.startRegistrationTimer()
                        }
                    }
                    
                    self.drawLandmarkDots(landmarks: landmarks, in: faceRect)
                    
                    DispatchQueue.main.async {
                        self.statusLabel.backgroundColor = UIColor.green.withAlphaComponent(0.7)
                    }
                } else {
                    // Face too small or not properly positioned
                    self.faceDetected = false
                    self.stopRegistrationTimer()
                    self.clearLandmarks()
                    DispatchQueue.main.async {
                        self.statusLabel.text = "Move closer to the camera"
                        self.statusLabel.backgroundColor = UIColor.orange.withAlphaComponent(0.7)
                    }
                }
            } else {
                self.faceDetected = false
                self.stopRegistrationTimer()
                self.clearLandmarks()
                DispatchQueue.main.async {
                    self.statusLabel.text = "Position your face in the circle"
                    self.statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
                }
            }
        }
        
        // Set higher accuracy for better landmark detection
        request.revision = VNDetectFaceLandmarksRequestRevision3
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}
