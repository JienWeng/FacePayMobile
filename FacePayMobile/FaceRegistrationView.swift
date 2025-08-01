//
//  FaceRegistrationView.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI
import AVFoundation
import Vision

struct FaceRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var faceDataManager = FaceDataManager()
    
    @State private var isScanning = false
    @State private var progress: Double = 0.0
    @State private var statusMessage = "Position your face in the circle"
    @State private var showSuccess = false
    @State private var livenessDetected = false
    @State private var faceQuality: Float = 0.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Camera view
            FaceCameraController(
                isScanning: $isScanning,
                progress: $progress,
                statusMessage: $statusMessage,
                showSuccess: $showSuccess,
                livenessDetected: $livenessDetected,
                faceQuality: $faceQuality,
                faceDataManager: faceDataManager
            )
            .ignoresSafeArea()
            
            // UI overlay
            VStack {
                Spacer()
                
                // Face circle overlay
                ZStack {
                    // Outer circle
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 3)
                        .frame(width: 280, height: 280)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            livenessDetected ? Color.green : Color.primaryYellow,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                    
                    // Quality indicator
                    if faceQuality > 0 {
                        Circle()
                            .fill(Color.green.opacity(Double(faceQuality)))
                            .frame(width: 20, height: 20)
                            .offset(y: -140)
                    }
                }
                
                Spacer()
                
                // Status and controls
                VStack(spacing: 20) {
                    // Status message
                    Text(statusMessage)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // Success checkmark
                    if showSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                            .scaleEffect(showSuccess ? 1.0 : 0.5)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showSuccess)
                    }
                    
                    // Start/Stop button
                    if !showSuccess {
                        Button(action: {
                            if isScanning {
                                stopScanning()
                            } else {
                                startScanning()
                            }
                        }) {
                            HStack {
                                Image(systemName: isScanning ? "stop.fill" : "camera.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text(isScanning ? "Stop Scanning" : "Start Scanning")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.primaryYellow)
                            .cornerRadius(25)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: showSuccess) { success in
            if success {
                // Auto-dismiss after successful registration
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    dismiss()
                }
            }
        }
    }
    
    private func startScanning() {
        isScanning = true
        progress = 0.0
        livenessDetected = false
        statusMessage = "Hold still while we scan..."
    }
    
    private func stopScanning() {
        isScanning = false
        progress = 0.0
        livenessDetected = false
        statusMessage = "Position your face in the circle"
    }
}

struct FaceCameraController: UIViewControllerRepresentable {
    @Binding var isScanning: Bool
    @Binding var progress: Double
    @Binding var statusMessage: String
    @Binding var showSuccess: Bool
    @Binding var livenessDetected: Bool
    @Binding var faceQuality: Float
    let faceDataManager: FaceDataManager
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = FaceCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let controller = uiViewController as? FaceCameraViewController {
            controller.isScanning = isScanning
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, FaceCameraDelegate {
        let parent: FaceCameraController
        private var scanStartTime: Date?
        private let scanDuration: TimeInterval = 3.0
        private var lastFaceObservation: VNFaceObservation?
        private var livenessFrames: [VNFaceObservation] = []
        
        init(_ parent: FaceCameraController) {
            self.parent = parent
        }
        
        func didDetectFace(_ observation: VNFaceObservation) {
            DispatchQueue.main.async {
                self.parent.faceQuality = observation.faceCaptureQuality ?? 0.0
                
                // Check if scanning should start
                if self.parent.isScanning && self.scanStartTime == nil {
                    self.scanStartTime = Date()
                    self.parent.statusMessage = "Hold still while we scan..."
                    self.livenessFrames.removeAll()
                }
                
                // Update progress
                if let startTime = self.scanStartTime {
                    let elapsed = Date().timeIntervalSince(startTime)
                    let progress = min(elapsed / self.scanDuration, 1.0)
                    self.parent.progress = progress
                    
                    // Collect frames for liveness detection
                    self.livenessFrames.append(observation)
                    
                    // Check liveness
                    if self.livenessFrames.count > 10 {
                        self.parent.livenessDetected = self.detectLiveness()
                    }
                    
                    // Complete scanning
                    if progress >= 1.0 && self.parent.livenessDetected {
                        self.completeScan(observation)
                    }
                }
            }
        }
        
        func didLoseFace() {
            DispatchQueue.main.async {
                if self.parent.isScanning && !self.parent.showSuccess {
                    self.resetScan()
                    self.parent.statusMessage = "Position your face in the circle"
                }
                self.parent.faceQuality = 0.0
            }
        }
        
        private func detectLiveness() -> Bool {
            guard livenessFrames.count >= 10 else { return false }
            
            // Simple liveness detection based on face movement
            let recentFrames = Array(livenessFrames.suffix(10))
            var movements: [Double] = []
            
            for i in 1..<recentFrames.count {
                let prev = recentFrames[i-1].boundingBox
                let curr = recentFrames[i].boundingBox
                
                let dx = abs(prev.midX - curr.midX)
                let dy = abs(prev.midY - curr.midY)
                let movement = sqrt(dx * dx + dy * dy)
                movements.append(movement)
            }
            
            let averageMovement = movements.reduce(0, +) / Double(movements.count)
            
            // Detect if there's subtle but consistent movement (indicating a live person)
            return averageMovement > 0.001 && averageMovement < 0.05
        }
        
        private func completeScan(_ observation: VNFaceObservation) {
            let faceFeatures = FaceFeatures(observation: observation)
            parent.faceDataManager.registerFace(faceFeatures)
            
            parent.statusMessage = "Registration successful!"
            parent.showSuccess = true
            parent.isScanning = false
            scanStartTime = nil
            livenessFrames.removeAll()
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
        
        private func resetScan() {
            scanStartTime = nil
            parent.progress = 0.0
            parent.livenessDetected = false
            livenessFrames.removeAll()
        }
    }
}

protocol FaceCameraDelegate: AnyObject {
    func didDetectFace(_ observation: VNFaceObservation)
    func didLoseFace()
}

class FaceCameraViewController: UIViewController {
    weak var delegate: FaceCameraDelegate?
    var isScanning: Bool = false
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreviewLayerFrame()
    }
    
    private func updatePreviewLayerFrame() {
        if let previewLayer = previewLayer {
            previewLayer.frame = view.bounds
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updatePreviewLayerFrame()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
    
    private func setupCamera() {
        // Check camera permission first
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureCameraSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configureCameraSession()
                    }
                }
            }
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }
    
    private func configureCameraSession() {
        // Check if running in simulator
        #if targetEnvironment(simulator)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let backgroundLayer = CALayer()
            backgroundLayer.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3).cgColor
            backgroundLayer.frame = self.view.bounds
            self.view.layer.insertSublayer(backgroundLayer, at: 0)
            
            let label = UILabel()
            label.text = "Face Registration\n(Simulator Mode)"
            label.textAlignment = .center
            label.numberOfLines = 0
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            label.frame = self.view.bounds
            self.view.addSubview(label)
        }
        return
        #endif
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
            
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
            }
            
            // Create and configure preview layer
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.previewLayer?.videoGravity = .resizeAspectFill
                self.previewLayer?.frame = self.view.bounds
                
                self.view.layer.insertSublayer(self.previewLayer!, at: 0)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.updatePreviewLayerFrame()
                }
            }
            
            // Start session on background queue
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.captureSession?.startRunning()
            }
            
        } catch {
            print("Error setting up face registration camera: \(error)")
        }
    }
}

extension FaceCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let faceDetectionRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let observations = request.results as? [VNFaceObservation], !observations.isEmpty else {
                DispatchQueue.main.async {
                    self?.delegate?.didLoseFace()
                }
                return
            }
            
            let faceObservation = observations[0]
            DispatchQueue.main.async {
                self?.delegate?.didDetectFace(faceObservation)
            }
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
        
        try? imageRequestHandler.perform([faceDetectionRequest])
    }
}

#Preview {
    FaceRegistrationView()
}
