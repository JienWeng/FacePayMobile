//
//  ICCameraView.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI
import AVFoundation

struct ICCameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> ICCameraViewController {
        let controller = ICCameraViewController()
        controller.onImageCaptured = onImageCaptured
        controller.onDismiss = onDismiss
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ICCameraViewController, context: Context) {}
}

class ICCameraViewController: UIViewController {
    var onImageCaptured: ((UIImage) -> Void)?
    var onDismiss: (() -> Void)?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    
    private let frameView = UIView()
    private let captureButton = UIButton()
    private let dismissButton = UIButton()
    private let loadingOverlay = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let loadingLabel = UILabel()
    
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
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            return
        }
        
        photoOutput = AVCapturePhotoOutput()
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)
    }
    
    private func setupUI() {
        // Frame for IC positioning
        frameView.backgroundColor = UIColor.clear
        frameView.layer.borderColor = UIColor.primaryYellow.cgColor
        frameView.layer.borderWidth = 3
        frameView.layer.cornerRadius = 12
        frameView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(frameView)
        
                // Capture button
        captureButton.backgroundColor = UIColor.primaryYellow
        captureButton.layer.borderColor = UIColor.black.cgColor
        captureButton.layer.borderWidth = 3
        captureButton.layer.cornerRadius = 35
        captureButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        captureButton.tintColor = .black
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(captureButton)
        
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
        
        // Add instruction label
        let instructionLabel = UILabel()
        instructionLabel.text = "Position your IC horizontally within the frame"
        instructionLabel.textColor = .white
        instructionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        instructionLabel.textAlignment = .center
        instructionLabel.font = UIFont.boldSystemFont(ofSize: 16)
        instructionLabel.layer.cornerRadius = 8
        instructionLabel.clipsToBounds = true
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        
        // Setup loading overlay
        setupLoadingOverlay()
        
        // Constraints
        NSLayoutConstraint.activate([
            // Frame view (IC frame) - landscape orientation
            frameView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            frameView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            frameView.widthAnchor.constraint(equalToConstant: 320),
            frameView.heightAnchor.constraint(equalToConstant: 200),
            
            // Instruction label
            instructionLabel.bottomAnchor.constraint(equalTo: frameView.topAnchor, constant: -20),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.heightAnchor.constraint(equalToConstant: 40),
            instructionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            // Capture button
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),
            
            // Dismiss button
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            dismissButton.widthAnchor.constraint(equalToConstant: 50),
            dismissButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupLoadingOverlay() {
        // Loading overlay background
        loadingOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        loadingOverlay.isHidden = true
        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingOverlay)
        
        // Loading indicator
        loadingIndicator.color = .white
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.addSubview(loadingIndicator)
        
        // Loading label
        loadingLabel.text = "Processing IC..."
        loadingLabel.textColor = .white
        loadingLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.addSubview(loadingLabel)
        
        // Loading overlay constraints
        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor, constant: -10),
            
            loadingLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 16),
            loadingLabel.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor)
        ])
    }
    
    private func showLoading() {
        loadingOverlay.isHidden = false
        loadingIndicator.startAnimating()
    }
    
    private func hideLoading() {
        loadingOverlay.isHidden = true
        loadingIndicator.stopAnimating()
    }
    
    private func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    private func stopSession() {
        captureSession.stopRunning()
    }
    
    @objc private func capturePhoto() {
        showLoading()
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func dismissCamera() {
        onDismiss?()
    }
}

extension ICCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        hideLoading()
        
        guard let imageData = photo.fileDataRepresentation(),
              let originalImage = UIImage(data: imageData) else {
            return
        }
        
        // Fix orientation to prevent rotation
        let fixedImage = originalImage.fixedOrientation()
        onImageCaptured?(fixedImage)
    }
}

extension UIImage {
    func fixedOrientation() -> UIImage {
        // If image is already in correct orientation, return as is
        if imageOrientation == .up {
            return self
        }
        
        // Create graphics context and draw image with correct orientation
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
    }
}
