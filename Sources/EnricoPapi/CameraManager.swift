import Foundation
import AVFoundation
import AppKit
import CoreImage

final class CameraManager: NSObject, ObservableObject, @unchecked Sendable {
    static let shared = CameraManager()
    
    @Published var isRunning: Bool = false
    @Published var permissionGranted: Bool = false
    @Published var currentFrame: NSImage? = nil
    @Published var errorMessage: String? = nil
    
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let ciContext = CIContext()
    
    override private init() {
        super.init()
        checkPermissions()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { self.permissionGranted = true }
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.permissionGranted = granted
                    if granted {
                        self.setupCamera()
                    } else {
                        self.errorMessage = "Accesso alla webcam negato. Abilitalo in Impostazioni di Sistema > Privacy e Sicurezza > Fotocamera."
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.permissionGranted = false
                self.errorMessage = "Accesso alla webcam negato. Abilitalo in Impostazioni di Sistema > Privacy e Sicurezza > Fotocamera."
            }
        @unknown default:
            break
        }
    }
    
    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .vga640x480
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                    ?? AVCaptureDevice.default(for: .video) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Nessuna fotocamera trovata."
                }
                self.captureSession.commitConfiguration()
                return
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                }
                
                self.videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
                ]
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.video.output"))
                
                if self.captureSession.canAddOutput(self.videoOutput) {
                    self.captureSession.addOutput(self.videoOutput)
                }
                
                self.captureSession.commitConfiguration()
                self.startSession()
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Errore apertura fotocamera: \(error.localizedDescription)"
                }
                self.captureSession.commitConfiguration()
            }
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.isRunning = true
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            DispatchQueue.main.async {
                self.isRunning = false
            }
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Pass frame to FaceTracker on MainActor
        Task { @MainActor in
            FaceTracker.shared.processPixelBuffer(pixelBuffer)
        }
        
        // Convert to NSImage for UI preview
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        if let cgImage = self.ciContext.createCGImage(ciImage, from: ciImage.extent) {
            let size = NSSize(width: ciImage.extent.width, height: ciImage.extent.height)
            let nsImage = NSImage(cgImage: cgImage, size: size)
            DispatchQueue.main.async {
                self.currentFrame = nsImage
            }
        }
    }
}
