//
//  FaceSignInView.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI
import AVFoundation
import Vision

struct FaceSignInView: View {
    @ObservedObject var userManager: UserManager
    @StateObject private var faceDataManager = FaceDataManager()
    @Environment(\.dismiss) private var dismiss
    @State private var isScanning = true
    @State private var progress: Double = 0.0
    @State private var statusMessage = "Look at the camera to sign in"
    @State private var authenticationResult: AuthResult?
    @State private var showResult = false
    
    enum AuthResult {
        case success
        case failed
        case noFaceRegistered
    }
    
    var body: some View {
        ZStack {
            // Black background as fallback
            Color.black
                .ignoresSafeArea()
            
            // Camera Background - This should be the main view
            FaceAuthController(
                isScanning: $isScanning,
                progress: $progress,
                statusMessage: $statusMessage,
                authenticationResult: $authenticationResult,
                showResult: $showResult,
                faceDataManager: faceDataManager
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            
            // Face detection frame overlay
            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: 3)
                .frame(width: 200, height: 200)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2 - 50)
            
            // Overlay UI
            VStack {
                Spacer()
                
                // Status message
                Text(statusMessage)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .multilineTextAlignment(.center)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.5))
                            .padding(.horizontal, -10)
                            .padding(.vertical, -5)
                    )
                
                Spacer().frame(height: 50)
                
                // Circular progress indicator
                ZStack {
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0.0, to: CGFloat(progress))
                        .stroke(
                            LinearGradient(                                gradient: Gradient(colors: getProgressColors()),
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 200, height: 400)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                    
                    // Center icon
                    Image(systemName: getCenterIcon())
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(getIconColor())
                        .scaleEffect(showResult ? 1.2 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showResult)
                }
                
                Spacer().frame(height: 80)
                
                // Action buttons
                HStack(spacing: 40) {
                    // Cancel button
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    
                    // Retry button (shown after failed auth)
                    if showResult && authenticationResult == .failed {
                        Button(action: {
                            resetAuthentication()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(Color.blue.opacity(0.6)))
                        }
                    }
                }
                
                Spacer().frame(height: 50)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: authenticationResult) { result in
            if result != nil {
                showResult = true
                
                if result == .success {
                    // Navigate to dashboard after short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        userManager.signIn()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getProgressColors() -> [Color] {
        switch authenticationResult {
        case .success:
            return [.green, .mint]
        case .failed:
            return [.red, .orange]
        case .noFaceRegistered:
            return [.yellow, .orange]
        case .none:
            return [.blue, .cyan]
        }
    }
    
    private func getCenterIcon() -> String {
        switch authenticationResult {
        case .success:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .noFaceRegistered:
            return "person.crop.circle.badge.exclamationmark"
        case .none:
            return "faceid"
        }
    }
    
    private func getIconColor() -> Color {
        switch authenticationResult {
        case .success:
            return .green
        case .failed:
            return .red
        case .noFaceRegistered:
            return .yellow
        case .none:
            return .white
        }
    }
    
    private func resetAuthentication() {
        authenticationResult = nil
        showResult = false
        progress = 0.0
        statusMessage = "Look at the camera to sign in"
        isScanning = true
    }
}

struct FaceAuthController: UIViewControllerRepresentable {
    @Binding var isScanning: Bool
    @Binding var progress: Double
    @Binding var statusMessage: String
    @Binding var authenticationResult: FaceSignInView.AuthResult?
    @Binding var showResult: Bool
    let faceDataManager: FaceDataManager
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = FaceAuthViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let controller = uiViewController as? FaceAuthViewController {
            controller.isScanning = isScanning
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, FaceAuthDelegate {
        let parent: FaceAuthController
        private var authStartTime: Date?
        private let authDuration: TimeInterval = 2.0
        private var authenticatingFace: VNFaceObservation?
        
        init(_ parent: FaceAuthController) {
            self.parent = parent
        }
        
        func didDetectFace(_ observation: VNFaceObservation) {
            DispatchQueue.main.async {
                // Check if we have registered face data
                guard self.parent.faceDataManager.isRegistered else {
                    self.parent.authenticationResult = .noFaceRegistered
                    self.parent.statusMessage = "No face registered. Please register first."
                    self.parent.isScanning = false
                    return
                }
                
                // Start authentication timer
                if self.parent.isScanning && self.authStartTime == nil {
                    self.authStartTime = Date()
                    self.authenticatingFace = observation
                    self.parent.statusMessage = "Authenticating..."
                }
                
                // Update progress
                if let startTime = self.authStartTime {
                    let elapsed = Date().timeIntervalSince(startTime)
                    let progress = min(elapsed / self.authDuration, 1.0)
                    self.parent.progress = progress
                    
                    // Complete authentication
                    if progress >= 1.0 {
                        self.completeAuthentication(observation)
                    }
                }
            }
        }
        
        func didLoseFace() {
            DispatchQueue.main.async {
                if self.parent.isScanning && !self.parent.showResult {
                    self.resetAuthentication()
                    self.parent.statusMessage = "Look at the camera to sign in"
                }
            }
        }
        
        private func completeAuthentication(_ observation: VNFaceObservation) {
            let currentFeatures = FaceFeatures(observation: observation)
            let similarity = parent.faceDataManager.compareFaces(currentFeatures)
            
            let threshold: Float = 0.75 // Adjust based on security requirements
            
            if similarity >= threshold {
                parent.authenticationResult = .success
                parent.statusMessage = "Authentication successful!"
                
                // Haptic feedback
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
            } else {
                parent.authenticationResult = .failed
                parent.statusMessage = "Authentication failed. Please try again."
                
                // Haptic feedback
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
            }
            
            parent.isScanning = false
            authStartTime = nil
            authenticatingFace = nil
        }
        
        private func resetAuthentication() {
            authStartTime = nil
            parent.progress = 0.0
            authenticatingFace = nil
        }
    }
}

protocol FaceAuthDelegate: AnyObject {
    func didDetectFace(_ observation: VNFaceObservation)
    func didLoseFace()
}

class FaceAuthViewController: UIViewController {
    weak var delegate: FaceAuthDelegate?
    var isScanning: Bool = true
    
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
            print("Preview layer frame updated to: \(view.bounds)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("FaceAuthViewController will appear")
        
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.captureSession?.startRunning()
                print("Restarted camera session")
            }
        }
        
        // Ensure preview layer is properly positioned
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
                    } else {
                        print("Camera permission denied")
                    }
                }
            }
        case .denied, .restricted:
            print("Camera access denied or restricted")
        @unknown default:
            print("Unknown camera authorization status")
        }
    }
    
    private func configureCameraSession() {
        // Check if running in simulator
        #if targetEnvironment(simulator)
        print("Running in simulator - camera preview not available")
        // Create a simple colored background to show the view is working
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let backgroundLayer = CALayer()
            backgroundLayer.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
            backgroundLayer.frame = self.view.bounds
            self.view.layer.insertSublayer(backgroundLayer, at: 0)
            
            // Add a label to show this is simulator mode
            let label = UILabel()
            label.text = "Camera Preview\n(Simulator Mode)"
            label.textAlignment = .center
            label.numberOfLines = 0
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            label.frame = self.view.bounds
            self.view.addSubview(label)
            
            print("Simulator camera placeholder added")
        }
        return
        #endif
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium // Use medium for better performance
        
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Unable to access front camera")
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
                
                // Ensure the preview layer is at the bottom of the view hierarchy
                self.view.layer.insertSublayer(self.previewLayer!, at: 0)
                
                print("Preview layer added with frame: \(self.view.bounds)")
                
                // Update the layer frame after a short delay to ensure proper layout
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.updatePreviewLayerFrame()
                }
            }
            
            // Start session on background queue
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.captureSession?.startRunning()
                print("Camera session started")
            }
            
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
}

extension FaceAuthViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isScanning else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let faceDetectionRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let observations = request.results as? [VNFaceObservation], !observations.isEmpty else {
                DispatchQueue.main.async {
                    self?.delegate?.didLoseFace()
                }
                return
            }
            
            // Use the first detected face
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
    FaceSignInView(userManager: UserManager())
}
